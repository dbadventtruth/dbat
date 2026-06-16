const std = @import("std");
const cdb = @import("cdb");
const http_api = @import("http_api.zig");

const posix = std.posix;
const ionet = std.Io.net;
const POLL = std.os.linux.POLL;

var allocator: std.mem.Allocator = undefined;
var global_io: std.Io = undefined;
var initialized = false;

var listener_fd: ?cdb.socklen_t = null;
var listener_ready = false;
var connections: std.array_list.Managed(*HttpConnection) = undefined;

var web_dir: []const u8 = "web";

pub fn setWebDir(dir: []const u8) void {
    web_dir = dir;
}

const HttpConnection = struct {
    fd: cdb.socklen_t,
    input: std.array_list.Managed(u8),
    output: std.array_list.Managed(u8),
    read_ready: bool = false,
    write_ready: bool = false,
    request_complete: bool = false,
    close_after_flush: bool = false,

    fn create(fd: cdb.socklen_t) !*HttpConnection {
        const conn = try allocator.create(HttpConnection);
        conn.* = .{
            .fd = fd,
            .input = std.array_list.Managed(u8).init(allocator),
            .output = std.array_list.Managed(u8).init(allocator),
        };
        try connections.append(conn);
        return conn;
    }

    fn destroy(self: *HttpConnection) void {
        for (connections.items, 0..) |item, i| {
            if (item == self) {
                _ = connections.swapRemove(i);
                break;
            }
        }
        self.input.deinit();
        self.output.deinit();
        allocator.destroy(self);
    }
};

pub fn init(alloc: std.mem.Allocator, io: std.Io) void {
    allocator = alloc;
    global_io = io;
    connections = std.array_list.Managed(*HttpConnection).init(alloc);
    initialized = true;
}

pub fn deinit() void {
    if (listener_fd) |fd| {
        _ = cdb.close(@intCast(fd));
        listener_fd = null;
    }
    for (connections.items) |conn| {
        conn.input.deinit();
        conn.output.deinit();
        allocator.destroy(conn);
    }
    connections.deinit();
    initialized = false;
}

pub fn openListener(port: u16) !void {
    if (!initialized) return error.NotInitialized;
    const address = ionet.IpAddress{ .ip4 = ionet.Ip4Address.unspecified(port) };
    const server = try ionet.IpAddress.listen(&address, global_io, .{
        .kernel_backlog = 5,
        .reuse_address = true,
    });
    const fd: cdb.socklen_t = @intCast(server.socket.handle);
    listener_fd = fd;
    cdb.nonblock(fd);
    cdb.mud_log("HTTP: listening on port %d", @as(c_int, port));
}

pub fn appendFds(fds: *std.array_list.Managed(posix.pollfd)) !void {
    if (listener_fd) |fd| {
        try fds.append(.{ .fd = @intCast(fd), .events = POLL.IN, .revents = 0 });
    }
    for (connections.items) |conn| {
        var events: i16 = POLL.IN;
        if (conn.output.items.len > 0) events |= POLL.OUT;
        try fds.append(.{ .fd = @intCast(conn.fd), .events = events, .revents = 0 });
    }
}

pub fn handleRevents(revents: []posix.pollfd) void {
    var i: usize = 0;
    if (listener_fd != null) {
        listener_ready = (revents[i].revents & POLL.IN) != 0;
        i += 1;
    }
    for (connections.items) |conn| {
        const r = revents[i].revents;
        conn.read_ready = (r & (POLL.IN | POLL.HUP)) != 0;
        conn.write_ready = (r & POLL.OUT) != 0;
        if ((r & (POLL.ERR | POLL.HUP | POLL.NVAL)) != 0) conn.close_after_flush = true;
        i += 1;
    }
}

pub fn acceptPending() void {
    if (listener_fd == null or !listener_ready) return;
    listener_ready = false;
    while (true) {
        var addr: cdb.struct_sockaddr_storage = .{};
        var addr_len: cdb.socklen_t = @sizeOf(cdb.struct_sockaddr_storage);
        const fd = cdb.accept(@intCast(listener_fd.?), @ptrCast(&addr), &addr_len);
        if (fd < 0) break;
        const conn = HttpConnection.create(@intCast(fd)) catch {
            _ = cdb.close(fd);
            continue;
        };
        cdb.nonblock(conn.fd);
    }
}

pub fn readPending() void {
    var i: usize = 0;
    while (i < connections.items.len) {
        const conn = connections.items[i];
        if (conn.read_ready and !conn.close_after_flush) {
            conn.read_ready = false;
            var buf: [4096]u8 = undefined;
            const n = posix.read(@intCast(conn.fd), &buf) catch {
                conn.close_after_flush = true;
                i += 1;
                continue;
            };
            if (n == 0) {
                conn.close_after_flush = true;
            } else {
                conn.input.appendSlice(buf[0..n]) catch {};
                if (!conn.request_complete) {
                    conn.request_complete = isRequestComplete(conn.input.items);
                }
            }
        }
        i += 1;
    }
}

pub fn processRequests() void {
    for (connections.items) |conn| {
        if (conn.request_complete) {
            conn.request_complete = false;
            processRequest(conn);
            conn.close_after_flush = true;
        }
    }
}

pub fn flushOutputs() void {
    var i: usize = 0;
    while (i < connections.items.len) {
        const conn = connections.items[i];
        if (conn.output.items.len > 0 and conn.write_ready) {
            conn.write_ready = false;
            const written = cdb.write(@intCast(conn.fd), conn.output.items.ptr, conn.output.items.len);
            if (written > 0) {
                const n: usize = @intCast(written);
                const remaining = conn.output.items[n..];
                std.mem.copyForwards(u8, conn.output.items[0..remaining.len], remaining);
                conn.output.resize(remaining.len) catch unreachable;
            } else if (written < 0) {
                conn.close_after_flush = true;
            }
        }
        i += 1;
    }
}

pub fn closeCompleted() void {
    var i: usize = 0;
    while (i < connections.items.len) {
        const conn = connections.items[i];
        if (conn.close_after_flush and conn.output.items.len == 0) {
            _ = cdb.close(@intCast(conn.fd));
            conn.destroy();
            // swapRemove moved last conn to position i; do not increment
        } else {
            i += 1;
        }
    }
}

fn isRequestComplete(input: []const u8) bool {
    const header_end = std.mem.indexOf(u8, input, "\r\n\r\n") orelse return false;
    const headers_section = input[0..header_end];
    var lines = std.mem.splitSequence(u8, headers_section, "\r\n");
    _ = lines.next(); // skip request line
    while (lines.next()) |line| {
        const colon = std.mem.indexOf(u8, line, ":") orelse continue;
        const name = std.mem.trim(u8, line[0..colon], " ");
        if (std.ascii.eqlIgnoreCase(name, "content-length")) {
            const value = std.mem.trim(u8, line[colon + 1 ..], " ");
            const cl = std.fmt.parseInt(usize, value, 10) catch return false;
            return input.len >= header_end + 4 + cl;
        }
    }
    return true;
}

fn processRequest(conn: *HttpConnection) void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const request = parseRequest(conn.input.items) catch {
        writeResponseToConn(conn, 400, "Bad Request", "text/plain", "bad request");
        return;
    };

    // API routes
    if (std.mem.startsWith(u8, request.path, "/api/")) {
        const response = http_api.dispatch(arena_alloc, &request) catch {
            writeResponseToConn(conn, 500, "Internal Server Error", "application/json", "{\"error\":\"internal error\"}");
            return;
        };
        writeResponseToConn(conn, response.status, response.status_text, "application/json", response.body);
        return;
    }

    // Static file serving
    serveStaticFile(conn, arena_alloc, request.path);
}

fn contentTypeForPath(path: []const u8) []const u8 {
    if (std.mem.endsWith(u8, path, ".html")) return "text/html; charset=utf-8";
    if (std.mem.endsWith(u8, path, ".js")) return "application/javascript";
    if (std.mem.endsWith(u8, path, ".css")) return "text/css";
    if (std.mem.endsWith(u8, path, ".ico")) return "image/x-icon";
    if (std.mem.endsWith(u8, path, ".png")) return "image/png";
    if (std.mem.endsWith(u8, path, ".svg")) return "image/svg+xml";
    if (std.mem.endsWith(u8, path, ".woff2")) return "font/woff2";
    if (std.mem.endsWith(u8, path, ".json")) return "application/json";
    return "application/octet-stream";
}

fn serveStaticFile(conn: *HttpConnection, alloc: std.mem.Allocator, req_path: []const u8) void {
    // Sanitize: reject traversal attempts
    var it = std.mem.splitScalar(u8, req_path, '/');
    while (it.next()) |component| {
        if (std.mem.eql(u8, component, "..")) {
            writeResponseToConn(conn, 403, "Forbidden", "text/plain", "forbidden");
            return;
        }
    }

    // Build filesystem path
    const effective_path = if (std.mem.eql(u8, req_path, "/")) "index.html" else req_path[1..];
    const fs_path = std.fmt.allocPrint(alloc, "{s}/{s}", .{ web_dir, effective_path }) catch {
        writeResponseToConn(conn, 500, "Internal Server Error", "text/plain", "internal error");
        return;
    };

    const body = std.Io.Dir.cwd().readFileAlloc(global_io, fs_path, alloc, .limited(8 * 1024 * 1024)) catch |err| {
        if (err == error.FileNotFound) {
            writeResponseToConn(conn, 404, "Not Found", "text/plain", "not found");
        } else {
            writeResponseToConn(conn, 500, "Internal Server Error", "text/plain", "internal error");
        }
        return;
    };

    writeResponseToConn(conn, 200, "OK", contentTypeForPath(fs_path), body);
}

fn parseRequest(input: []const u8) !http_api.ParsedRequest {
    const header_end = std.mem.indexOf(u8, input, "\r\n\r\n") orelse return error.Incomplete;

    var result: http_api.ParsedRequest = .{
        .method = "",
        .path = "",
        .body = input[header_end + 4 ..],
        .headers = undefined,
        .header_count = 0,
    };

    var lines = std.mem.splitSequence(u8, input[0..header_end], "\r\n");

    const request_line = lines.next() orelse return error.InvalidRequest;
    var parts = std.mem.splitScalar(u8, request_line, ' ');
    result.method = parts.next() orelse return error.InvalidRequest;
    result.path = parts.next() orelse return error.InvalidRequest;

    // Strip query string from path
    if (std.mem.indexOf(u8, result.path, "?")) |q| {
        result.path = result.path[0..q];
    }

    while (lines.next()) |line| {
        if (result.header_count >= 16) break;
        const colon = std.mem.indexOf(u8, line, ":") orelse continue;
        result.headers[result.header_count] = .{
            .name = std.mem.trim(u8, line[0..colon], " "),
            .value = std.mem.trim(u8, line[colon + 1 ..], " "),
        };
        result.header_count += 1;
    }

    if (result.getHeader("content-length")) |cl_str| {
        const cl = std.fmt.parseInt(usize, std.mem.trim(u8, cl_str, " "), 10) catch 0;
        if (cl <= result.body.len) result.body = result.body[0..cl];
    }

    return result;
}

fn writeResponseToConn(conn: *HttpConnection, status: u16, status_text: []const u8, content_type: []const u8, body: []const u8) void {
    var header_buf: [512]u8 = undefined;
    const headers = std.fmt.bufPrint(
        &header_buf,
        "HTTP/1.1 {d} {s}\r\nContent-Type: {s}\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n",
        .{ status, status_text, content_type, body.len },
    ) catch return;
    conn.output.appendSlice(headers) catch return;
    conn.output.appendSlice(body) catch return;
}
