const std = @import("std");
const db = @import("db");
const cdb = @import("cdb");

pub const Options = struct {
    file: ?[]const u8 = null,
    dir: []const u8 = "lua/tests",
    filter: ?[]const u8 = null,
};

pub fn run(init: std.process.Init, options: Options) u8 {
    cdb.log("Running test mode.");

    var passed: usize = 0;
    var failed: usize = 0;

    if (options.file) |path| {
        runOne(path, &passed, &failed);
    } else {
        runDir(init, options, &passed, &failed) catch |err| {
            std.log.err("test mode failed to scan {s}: {s}", .{ options.dir, @errorName(err) });
            return 1;
        };
    }

    std.log.info("test mode summary: {} passed, {} failed", .{ passed, failed });
    cdb.log(
        "Test mode summary: %d passed, %d failed.",
        @as(c_int, @intCast(passed)),
        @as(c_int, @intCast(failed)),
    );

    if (failed != 0) return 1;
    if (passed == 0) {
        std.log.err("test mode found no tests to run", .{});
        return 1;
    }
    return 0;
}

fn runDir(init: std.process.Init, options: Options, passed: *usize, failed: *usize) !void {
    const files = try collectLuaFiles(init, options.dir, options.filter);
    defer {
        for (files) |path| init.gpa.free(path);
        init.gpa.free(files);
    }

    for (files) |path| runOne(path, passed, failed);
}

fn runOne(path: []const u8, passed: *usize, failed: *usize) void {
    std.log.info("running Lua test {s}", .{path});
    const ok = db.lua_api.runFile(path) catch |err| {
        std.log.err("Lua test {s} failed: {s}", .{ path, @errorName(err) });
        failed.* += 1;
        return;
    };

    if (ok) {
        passed.* += 1;
    } else {
        std.log.err("Lua test {s} returned false", .{path});
        failed.* += 1;
    }
}

fn collectLuaFiles(init: std.process.Init, dir_path: []const u8, filter: ?[]const u8) ![][]const u8 {
    var dir = try std.Io.Dir.cwd().openDir(init.io, dir_path, .{ .iterate = true });
    defer dir.close(init.io);

    var walker = try dir.walk(init.gpa);
    defer walker.deinit();

    var list = std.array_list.Managed([]const u8).init(init.gpa);
    errdefer {
        for (list.items) |path| init.gpa.free(path);
        list.deinit();
    }

    while (try walker.next(init.io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.path, ".lua")) continue;
        if (filter) |needle| {
            if (std.mem.indexOf(u8, entry.path, needle) == null) continue;
        }
        try list.append(try std.fmt.allocPrint(init.gpa, "{s}/{s}", .{ dir_path, entry.path }));
    }

    const files = try list.toOwnedSlice();
    std.mem.sort([]const u8, files, {}, stringLessThan);
    return files;
}

fn stringLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}
