const std = @import("std");

pub const ScriptInstance = struct {
    id: []const u8,
    numbers: std.StringHashMap(i64),
    strings: std.StringHashMap([]const u8),

    pub fn init(alloc: std.mem.Allocator, id: []const u8) ScriptInstance {
        return .{
            .id = id,
            .numbers = std.StringHashMap(i64).init(alloc),
            .strings = std.StringHashMap([]const u8).init(alloc),
        };
    }

    pub fn deinit(self: *ScriptInstance, alloc: std.mem.Allocator) void {
        var sit = self.strings.iterator();
        while (sit.next()) |e| alloc.free(e.value_ptr.*);
        self.strings.deinit();
        self.numbers.deinit();
    }
};
