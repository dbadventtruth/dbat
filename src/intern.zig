const std = @import("std");

pub const InternedId = u32;
pub const INVALID_ID = std.math.maxInt(InternedId);

var gpa: std.mem.Allocator = undefined;
var name_to_id: std.StringHashMap(InternedId) = undefined;
var id_to_name: std.array_list.Managed([]const u8) = undefined;
var ready = false;

pub fn init(alloc: std.mem.Allocator) void {
    gpa = alloc;
    name_to_id = std.StringHashMap(InternedId).init(alloc);
    id_to_name = std.array_list.Managed([]const u8).init(alloc);
    ready = true;
}

pub fn deinit() void {
    if (!ready) return;
    for (id_to_name.items) |name| gpa.free(name);
    name_to_id.deinit();
    id_to_name.deinit();
    ready = false;
}

pub fn intern(name: []const u8) InternedId {
    if (name_to_id.get(name)) |id| return id;
    const id: InternedId = @intCast(id_to_name.items.len);
    const owned = gpa.dupe(u8, name) catch @panic("intern OOM");
    id_to_name.append(owned) catch @panic("intern OOM");
    name_to_id.put(owned, id) catch @panic("intern OOM");
    return id;
}

pub fn lookup(name: []const u8) ?InternedId {
    return name_to_id.get(name);
}

pub fn nameOf(id: InternedId) []const u8 {
    return id_to_name.items[id];
}

pub fn count() usize {
    return id_to_name.items.len;
}

pub export fn intern_string(ptr: ?[*:0]const u8) InternedId {
    const name = ptr orelse return INVALID_ID;
    if (std.mem.len(name) == 0) return INVALID_ID;
    return intern(std.mem.span(name));
}

pub export fn lookup_string(ptr: ?[*:0]const u8) i64 {
    const name = ptr orelse return -1;
    if (std.mem.len(name) == 0) return -1;
    return if (lookup(std.mem.span(name))) |id| @intCast(id) else -1;
}
