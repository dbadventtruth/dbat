const cdb = @import("cdb");
const std = @import("std");
const bitflags = @import("flags.zig");
const intern_mod = @import("intern.zig");
const lua_api = @import("lua_api.zig");
const script_instance_mod = @import("script_instance.zig");

extern fn strdup(s: [*:0]const u8) ?[*:0]u8;

const ScriptInstance = script_instance_mod.ScriptInstance;
const ScriptId = intern_mod.InternedId;
const ScriptMap = std.AutoHashMap(ScriptId, ScriptInstance);

var zone_script_allocator: std.mem.Allocator = undefined;
var zone_scripts_global: std.AutoHashMap(i64, ScriptMap) = undefined;

pub fn init(alloc: std.mem.Allocator) void {
    zone_script_allocator = alloc;
    zone_scripts_global = std.AutoHashMap(i64, ScriptMap).init(alloc);
}

pub fn deinit() void {
    var outer = zone_scripts_global.iterator();
    while (outer.next()) |entry| {
        var inner = entry.value_ptr.iterator();
        while (inner.next()) |se| {
            se.value_ptr.deinit(zone_script_allocator);
        }
        entry.value_ptr.deinit();
    }
    zone_scripts_global.deinit();
}

fn zoneKey(zone: *cdb.zone_data) i64 {
    return @as(i64, @intCast(cdb.zone_id_get(zone)));
}

fn getZoneScriptMap(zone: *cdb.zone_data) ?*ScriptMap {
    return zone_scripts_global.getPtr(zoneKey(zone));
}

fn getOrCreateZoneScriptMap(zone: *cdb.zone_data) ?*ScriptMap {
    const result = zone_scripts_global.getOrPut(zoneKey(zone)) catch return null;
    if (!result.found_existing) {
        result.value_ptr.* = ScriptMap.init(zone_script_allocator);
    }
    return result.value_ptr;
}

pub export fn zone_script_add(zone: *cdb.zone_data, script_id: ?[*:0]const u8) bool {
    const id_z = script_id orelse return false;
    const id = std.mem.span(id_z);
    const interned = intern_mod.lookup(id) orelse return false;
    const map = getOrCreateZoneScriptMap(zone) orelse return false;
    if (map.contains(interned)) return false;
    const instance = ScriptInstance.init(zone_script_allocator, intern_mod.nameOf(interned));
    map.put(interned, instance) catch return false;
    lua_api.callZoneScriptHook(zone, id, "on_apply", null);
    return true;
}

pub export fn zone_script_remove(zone: *cdb.zone_data, script_id: ?[*:0]const u8, reason: ?[*:0]const u8) bool {
    const id_z = script_id orelse return false;
    const id = std.mem.span(id_z);
    const interned = intern_mod.lookup(id) orelse return false;
    const map = getZoneScriptMap(zone) orelse return false;
    if (!map.contains(interned)) return false;
    const reason_str: ?[]const u8 = if (reason) |r| std.mem.span(r) else null;
    lua_api.callZoneScriptHook(zone, id, "on_remove", reason_str);
    if (map.fetchRemove(interned)) |kv| {
        var instance = kv.value;
        instance.deinit(zone_script_allocator);
    }
    return true;
}

pub export fn zone_script_has(zone: *cdb.zone_data, script_id: ?[*:0]const u8) bool {
    const id_z = script_id orelse return false;
    const interned = intern_mod.lookup(std.mem.span(id_z)) orelse return false;
    const map = getZoneScriptMap(zone) orelse return false;
    return map.contains(interned);
}

pub export fn zone_script_number_get(zone: *cdb.zone_data, script_id: ?[*:0]const u8, key: ?[*:0]const u8) i64 {
    const id_z = script_id orelse return 0;
    const key_z = key orelse return 0;
    const interned = intern_mod.lookup(std.mem.span(id_z)) orelse return 0;
    const map = getZoneScriptMap(zone) orelse return 0;
    const instance = map.getPtr(interned) orelse return 0;
    return instance.numbers.get(std.mem.span(key_z)) orelse 0;
}

pub export fn zone_script_number_set(zone: *cdb.zone_data, script_id: ?[*:0]const u8, key: ?[*:0]const u8, value: i64) void {
    const id_z = script_id orelse return;
    const key_z = key orelse return;
    const interned = intern_mod.lookup(std.mem.span(id_z)) orelse return;
    const map = getZoneScriptMap(zone) orelse return;
    const instance = map.getPtr(interned) orelse return;
    instance.numbers.put(lua_api.internString(std.mem.span(key_z)), value) catch {};
}

pub export fn zone_script_text_get(zone: *cdb.zone_data, script_id: ?[*:0]const u8, key: ?[*:0]const u8) [*c]const u8 {
    const id_z = script_id orelse return null;
    const key_z = key orelse return null;
    const interned = intern_mod.lookup(std.mem.span(id_z)) orelse return null;
    const map = getZoneScriptMap(zone) orelse return null;
    const instance = map.getPtr(interned) orelse return null;
    return @ptrCast(instance.strings.get(std.mem.span(key_z)) orelse return null);
}

pub export fn zone_script_text_set(zone: *cdb.zone_data, script_id: ?[*:0]const u8, key: ?[*:0]const u8, value: ?[*:0]const u8) void {
    const id_z = script_id orelse return;
    const key_z = key orelse return;
    const val_z = value orelse return;
    const interned = intern_mod.lookup(std.mem.span(id_z)) orelse return;
    const map = getZoneScriptMap(zone) orelse return;
    const instance = map.getPtr(interned) orelse return;
    const key_str = lua_api.internString(std.mem.span(key_z));
    const val_copy = zone_script_allocator.dupe(u8, std.mem.span(val_z)) catch return;
    if (instance.strings.fetchPut(key_str, val_copy) catch null) |old| {
        zone_script_allocator.free(old.value);
    }
}

pub export fn zone_script_event_dispatch(zone: *cdb.zone_data, script_id: ?[*:0]const u8, event_name: ?[*:0]const u8) void {
    const id_z = script_id orelse return;
    const ev_z = event_name orelse return;
    lua_api.callZoneScriptEventHook(zone, std.mem.span(id_z), std.mem.span(ev_z));
}

pub const ZoneScriptEntry = struct { name: []const u8 };

pub const ZoneScriptIterator = struct {
    inner: ScriptMap.Iterator,

    pub fn next(self: *ZoneScriptIterator) ?ZoneScriptEntry {
        const kv = self.inner.next() orelse return null;
        return .{ .name = intern_mod.nameOf(kv.key_ptr.*) };
    }
};

pub fn zoneScriptIterator(zone: *const cdb.zone_data) ?ZoneScriptIterator {
    const key = @as(i64, @intCast(cdb.zone_id_get(@constCast(zone))));
    const map = zone_scripts_global.getPtr(key) orelse return null;
    return .{ .inner = map.iterator() };
}

pub export fn zone_id_get(zone: *cdb.zone_data) cdb.zone_vnum { return zone.id; }
pub export fn zone_id_set(zone: *cdb.zone_data, id: cdb.zone_vnum) void { zone.id = id; }
pub export fn zone_name_get(zone: *cdb.zone_data) [*c]const u8 { return zone.name; }
pub export fn zone_name_set(zone: *cdb.zone_data, value: ?[*:0]const u8) void { replaceString(&zone.name, value); }
pub export fn zone_builders_get(zone: *cdb.zone_data) [*c]const u8 { return zone.builders; }
pub export fn zone_builders_set(zone: *cdb.zone_data, value: ?[*:0]const u8) void { replaceString(&zone.builders, value); }
pub export fn zone_lifespan_get(zone: *cdb.zone_data) c_int { return zone.lifespan; }
pub export fn zone_lifespan_set(zone: *cdb.zone_data, lifespan: c_int) void { zone.lifespan = lifespan; }
pub export fn zone_age_get(zone: *cdb.zone_data) c_int { return zone.age; }
pub export fn zone_age_set(zone: *cdb.zone_data, age: c_int) void { zone.age = age; }
pub export fn zone_bottom_get(zone: *cdb.zone_data) cdb.room_vnum { return zone.bot; }
pub export fn zone_bottom_set(zone: *cdb.zone_data, bottom: cdb.room_vnum) void { zone.bot = bottom; }
pub export fn zone_top_get(zone: *cdb.zone_data) cdb.room_vnum { return zone.top; }
pub export fn zone_top_set(zone: *cdb.zone_data, top: cdb.room_vnum) void { zone.top = top; }
pub export fn zone_reset_mode_get(zone: *cdb.zone_data) c_int { return zone.reset_mode; }
pub export fn zone_reset_mode_set(zone: *cdb.zone_data, mode: c_int) void { zone.reset_mode = mode; }
pub export fn zone_min_level_get(zone: *cdb.zone_data) c_int { return zone.min_level; }
pub export fn zone_min_level_set(zone: *cdb.zone_data, level: c_int) void { zone.min_level = level; }
pub export fn zone_max_level_get(zone: *cdb.zone_data) c_int { return zone.max_level; }
pub export fn zone_max_level_set(zone: *cdb.zone_data, level: c_int) void { zone.max_level = level; }
pub export fn zone_flagged(zone: *cdb.zone_data, pos: c_int) bool { return bitflags.get(&zone.zone_flags, pos); }
pub export fn zone_flag_toggle(zone: *cdb.zone_data, pos: c_int) bool { return bitflags.toggle(&zone.zone_flags, pos); }
pub export fn zone_flag_set(zone: *cdb.zone_data, pos: c_int, value: bool) void { bitflags.set(&zone.zone_flags, pos, value); }
pub export fn zone_command_get(zone: *cdb.zone_data, index: usize) [*c]cdb.reset_com { if (zone.cmd == null) return null; return &zone.cmd[index]; }

pub export fn zone_command_type_get(cmd: *cdb.reset_com) u8 { return cmd.command; }
pub export fn zone_command_type_set(cmd: *cdb.reset_com, command: u8) void { cmd.command = command; }
pub export fn zone_command_if_flag_get(cmd: *cdb.reset_com) bool { return cmd.if_flag; }
pub export fn zone_command_if_flag_set(cmd: *cdb.reset_com, value: bool) void { cmd.if_flag = value; }
pub export fn zone_command_arg_get(cmd: *cdb.reset_com, index: usize) c_int { return switch (index) { 0 => cmd.arg1, 1 => cmd.arg2, 2 => cmd.arg3, 3 => cmd.arg4, 4 => cmd.arg5, else => 0 }; }
pub export fn zone_command_arg_set(cmd: *cdb.reset_com, index: usize, value: c_int) void { switch (index) { 0 => cmd.arg1 = value, 1 => cmd.arg2 = value, 2 => cmd.arg3 = value, 3 => cmd.arg4 = value, 4 => cmd.arg5 = value, else => {} } }
pub export fn zone_command_line_get(cmd: *cdb.reset_com) c_int { return cmd.line; }
pub export fn zone_command_line_set(cmd: *cdb.reset_com, line: c_int) void { cmd.line = line; }
pub export fn zone_command_sarg1_get(cmd: *cdb.reset_com) [*c]const u8 { return cmd.sarg1; }
pub export fn zone_command_sarg1_set(cmd: *cdb.reset_com, value: ?[*:0]const u8) void { replaceString(&cmd.sarg1, value); }
pub export fn zone_command_sarg2_get(cmd: *cdb.reset_com) [*c]const u8 { return cmd.sarg2; }
pub export fn zone_command_sarg2_set(cmd: *cdb.reset_com, value: ?[*:0]const u8) void { replaceString(&cmd.sarg2, value); }

fn replaceString(field: *[*c]u8, value: ?[*:0]const u8) void { const new_value = if (value) |s| strdup(s) orelse return else null; if (field.* != null) std.c.free(field.*); field.* = new_value; }
