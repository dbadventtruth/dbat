const std = @import("std");
const cdb = @import("cdb");

const Allocator = std.mem.Allocator;

extern fn malloc(size: usize) ?[*]u8;
extern fn free(ptr: ?*anyopaque) void;

var allocator: Allocator = undefined;
var global_io: std.Io = undefined;
var initialized = false;

var listener_fd: ?cdb.socklen_t = null;
var connections: std.array_list.Managed(*Connection) = undefined;
var accept_callback: ?*const fn (fd: cdb.socklen_t, host: [*:0]const u8, conn: *Connection) callconv(.c) ?*cdb.descriptor_data = null;

pub const Connection = struct {
    fd: cdb.socklen_t,
    desc: ?*cdb.descriptor_data = null,
    host: [:0]u8,
    input: std.array_list.Managed(u8),
    output: std.array_list.Managed(u8),

    fn create(fd: cdb.socklen_t) !*Connection {
        const conn = try allocator.create(Connection);
        conn.* = .{
            .fd = fd,
            .host = try allocator.dupeZ(u8, ""),
            .input = std.array_list.Managed(u8).init(allocator),
            .output = std.array_list.Managed(u8).init(allocator),
        };
        try connections.append(conn);
        return conn;
    }

    fn destroy(self: *Connection) void {
        unregisterConnection(self);
        allocator.free(self.host);
        self.input.deinit();
        self.output.deinit();
        allocator.destroy(self);
    }

    fn setString(self: *Connection, field: *[:0]u8, value: ?[*:0]const u8) !void {
        const replacement = try allocator.dupeZ(u8, cString(value));
        allocator.free(field.*);
        field.* = replacement;
        _ = self;
    }
};

pub fn init(alloc: Allocator, io: std.Io) void {
    allocator = alloc;
    global_io = io;
    connections = std.array_list.Managed(*Connection).init(allocator);
    initialized = true;
}

pub fn deinit() void {
    for (connections.items) |conn| {
        allocator.free(conn.host);
        conn.input.deinit();
        conn.output.deinit();
        allocator.destroy(conn);
    }
    connections.deinit();
    listener_fd = null;
    accept_callback = null;
    initialized = false;
}

pub export fn net_listener_adopt(fd: cdb.socklen_t) bool {
    listener_fd = fd;
    return true;
}

pub export fn net_accept_callback_set(callback: ?*const fn (fd: cdb.socklen_t, host: [*:0]const u8, conn: *Connection) callconv(.c) ?*cdb.descriptor_data) void {
    accept_callback = callback;
}

pub export fn net_connection_create(fd: cdb.socklen_t) ?*Connection {
    if (!initialized) return null;
    return Connection.create(fd) catch null;
}

pub export fn net_connection_destroy(conn: ?*Connection) void {
    if (conn) |value| value.destroy();
}

pub export fn net_connection_fd(conn: ?*const Connection) cdb.socklen_t {
    return if (conn) |value| value.fd else 0;
}

pub export fn net_connection_descriptor_set(conn: ?*Connection, desc: ?*cdb.descriptor_data) void {
    if (conn) |value| value.desc = desc;
}

pub export fn net_connection_descriptor(conn: ?*const Connection) ?*cdb.descriptor_data {
    return if (conn) |value| value.desc else null;
}

pub export fn net_connection_host_set(conn: ?*Connection, host: ?[*:0]const u8) bool {
    if (conn) |value| {
        value.setString(&value.host, host) catch return false;
        return true;
    }
    return false;
}

pub export fn net_connection_host(conn: ?*const Connection) [*:0]const u8 {
    return if (conn) |value| value.host.ptr else emptyString();
}

pub export fn net_connection_send(conn: ?*Connection, bytes: ?[*]const u8, len: usize) bool {
    const value = conn orelse return false;
    if (len == 0) return true;
    const ptr = bytes orelse return false;
    value.output.appendSlice(ptr[0..len]) catch return false;
    return true;
}

pub export fn net_connection_pop_line(conn: ?*Connection) ?[*:0]u8 {
    const value = conn orelse return null;
    const end = std.mem.indexOf(u8, value.input.items, "\r\n") orelse return null;
    const line = cOwnedLine(value.input.items[0..end]) catch return null;

    const consumed = end + 2;
    const remaining = value.input.items[consumed..];
    std.mem.copyForwards(u8, value.input.items[0..remaining.len], remaining);
    value.input.resize(remaining.len) catch unreachable;
    return line;
}

pub export fn net_connection_free_line(line: ?[*:0]u8) void {
    free(line);
}

pub export fn net_accept_all_pending() c_int {
    // Socket accept is intentionally not wired yet. When wired, this will create a
    // Connection and call accept_callback(fd, host, conn) to allocate/link descriptor_data.
    if (listener_fd == null) return 0;
    if (accept_callback == null) return 0;
    return 0;
}

pub export fn net_read_all_pending() c_int {
    // Future seam: read nonblocking bytes from each Connection fd into input buffers.
    return 0;
}

pub export fn net_flush_all_outputs() c_int {
    // Future seam: flush queued output bytes from each Connection to its fd.
    return 0;
}

pub export fn net_copyover_dump(path: ?[*:0]const u8) bool {
    if (!initialized) return false;
    writeSnapshot(cString(path)) catch return false;
    return true;
}

pub export fn net_copyover_recover(path: ?[*:0]const u8) bool {
    if (!initialized) return false;
    recoverSnapshot(cString(path)) catch return false;
    return true;
}

fn unregisterConnection(conn: *Connection) void {
    for (connections.items, 0..) |item, index| {
        if (item == conn) {
            _ = connections.swapRemove(index);
            return;
        }
    }
}

fn writeSnapshot(path: []const u8) !void {
    var root = std.json.Value{ .object = std.json.ObjectMap.empty };

    try root.object.put(allocator, "version", .{ .integer = 1 });
    try root.object.put(allocator, "process_id", .{ .integer = cdb.getpid() });
    try root.object.put(allocator, "listener_fd", .{ .integer = listener_fd orelse 0 });

    var array = std.json.Array.init(allocator);
    errdefer array.deinit();
    for (connections.items) |conn| {
        if (!shouldDumpConnection(conn.desc)) continue;
        try array.append(try connectionToJson(conn));
    }
    var desc = cdb.descriptor_list;
    while (desc != null) : (desc = desc.*.next) {
        if (descriptorHasRegisteredConnection(desc.?)) continue;
        if (!shouldDumpConnection(desc)) continue;
        try array.append(try descriptorToJson(desc.?));
    }
    try root.object.put(allocator, "connections", .{ .array = array });

    var out: std.Io.Writer.Allocating = .init(allocator);
    defer out.deinit();
    try std.json.Stringify.value(root, .{ .whitespace = .indent_2 }, &out.writer);
    try out.writer.writeByte('\n');
    try std.Io.Dir.cwd().writeFile(global_io, .{ .sub_path = path, .data = out.written() });
}

fn recoverSnapshot(path: []const u8) !void {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(global_io, path, allocator, .limited(16 * 1024 * 1024));
    defer allocator.free(bytes);

    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, bytes, .{});
    defer parsed.deinit();

    const root = parsed.value.object;
    const listener_value = root.get("listener_fd") orelse return error.InvalidCopyoverSnapshot;
    const recovered_listener_fd: cdb.socklen_t = @intCast(listener_value.integer);
    _ = net_listener_adopt(recovered_listener_fd);
    cdb.mother_desc = recovered_listener_fd;

    cdb.copyover_recover_begin();

    const connections_value = root.get("connections") orelse return error.InvalidCopyoverSnapshot;
    for (connections_value.array.items) |item| {
        try recoverConnection(item.object);
    }

    _ = cdb.unlink(path.ptr);
}

fn connectionToJson(conn: *const Connection) !std.json.Value {
    const desc = conn.desc orelse return descriptorToJson(null);
    var object = try descriptorToJson(desc);

    try object.object.put(allocator, "fd", .{ .integer = conn.fd });
    try object.object.put(allocator, "host", .{ .string = try allocator.dupe(u8, conn.host) });
    try object.object.put(allocator, "input_b64", .{ .string = try encodeBase64(conn.input.items) });
    try object.object.put(allocator, "output_b64", .{ .string = try encodeBase64(conn.output.items) });
    return object;
}

fn descriptorToJson(desc: ?*const cdb.descriptor_data) !std.json.Value {
    var object = std.json.Value{ .object = std.json.ObjectMap.empty };
    const value = desc orelse return object;

    try object.object.put(allocator, "fd", .{ .integer = value.descriptor });
    try object.object.put(allocator, "character_id", .{ .integer = descriptorCharacterId(value) });
    try object.object.put(allocator, "state", .{ .integer = value.connected });
    try object.object.put(allocator, "host", .{ .string = try allocator.dupe(u8, std.mem.sliceTo(&value.host, 0)) });
    try object.object.put(allocator, "name", .{ .string = try allocator.dupe(u8, std.mem.span(cdb.copyover_descriptor_character_name(value))) });
    try object.object.put(allocator, "username", .{ .string = try allocator.dupe(u8, cString(value.user)) });
    try object.object.put(allocator, "saved_loadroom", .{ .integer = descriptorLoadRoom(value) });
    try object.object.put(allocator, "input_b64", .{ .string = try encodeBase64(&.{}) });
    try object.object.put(allocator, "output_b64", .{ .string = try encodeBase64(&.{}) });
    return object;
}

fn recoverConnection(object: std.json.ObjectMap) !void {
    const fd: cdb.socklen_t = @intCast((object.get("fd") orelse return error.InvalidCopyoverSnapshot).integer);
    const host = (object.get("host") orelse return error.InvalidCopyoverSnapshot).string;
    const name = (object.get("name") orelse return error.InvalidCopyoverSnapshot).string;
    const username = if (object.get("username")) |value| value.string else "Empty";
    const saved_loadroom: c_int = @intCast((object.get("saved_loadroom") orelse return error.InvalidCopyoverSnapshot).integer);

    const conn = try Connection.create(fd);
    errdefer conn.destroy();
    allocator.free(conn.host);
    conn.host = try allocator.dupeZ(u8, host);
    if (object.get("input_b64")) |value| try decodeBase64Append(&conn.input, value.string);
    if (object.get("output_b64")) |value| try decodeBase64Append(&conn.output, value.string);

    const name_z = try allocator.dupeZ(u8, name);
    defer allocator.free(name_z);
    const username_z = try allocator.dupeZ(u8, username);
    defer allocator.free(username_z);

    cdb.copyover_recover_descriptor(fd, name_z.ptr, conn.host.ptr, saved_loadroom, username_z.ptr, @ptrCast(conn));
}

fn connectionCharacterId(conn: *const Connection) i64 {
    const desc = conn.desc orelse return 0;
    return descriptorCharacterId(desc);
}

fn connectionState(conn: *const Connection) c_int {
    const desc = conn.desc orelse return 0;
    return desc.connected;
}

fn shouldDumpConnection(desc: ?*const cdb.descriptor_data) bool {
    const value = desc orelse return false;
    return value.connected == cdb.CON_PLAYING and value.character != null;
}

fn descriptorHasRegisteredConnection(desc: *const cdb.descriptor_data) bool {
    for (connections.items) |conn| {
        if (conn.desc == desc) return true;
    }
    return false;
}

fn descriptorCharacterId(desc: *const cdb.descriptor_data) i64 {
    const ch = desc.character orelse return 0;
    return cdb.char_id_get(ch);
}

fn descriptorLoadRoom(desc: *const cdb.descriptor_data) c_int {
    return cdb.copyover_descriptor_saved_loadroom(desc);
}

fn encodeBase64(bytes: []const u8) ![]u8 {
    const encoder = std.base64.standard.Encoder;
    const out = try allocator.alloc(u8, encoder.calcSize(bytes.len));
    _ = encoder.encode(out, bytes);
    return out;
}

fn decodeBase64Append(list: *std.array_list.Managed(u8), text: []const u8) !void {
    const decoder = std.base64.standard.Decoder;
    const len = try decoder.calcSizeForSlice(text);
    const start = list.items.len;
    try list.resize(start + len);
    try decoder.decode(list.items[start..], text);
}

fn cOwnedLine(bytes: []const u8) ![*:0]u8 {
    const raw = malloc(bytes.len + 1) orelse return error.OutOfMemory;
    const slice = raw[0 .. bytes.len + 1];
    @memcpy(slice[0..bytes.len], bytes);
    slice[bytes.len] = 0;
    return @ptrCast(raw);
}

fn cString(value: ?[*:0]const u8) []const u8 {
    const ptr = value orelse return "";
    return std.mem.span(ptr);
}

fn emptyString() [*:0]const u8 {
    return "";
}
