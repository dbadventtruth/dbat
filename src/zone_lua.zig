const std = @import("std");
const zlua = @import("zlua");
const cdb = @import("cdb");

const Lua = zlua.Lua;
const zone_metatable = "dbat.Zone";

extern fn event_schedule_lua_zone_update(fire_at: i64, interval: i64, kind: ?[*:0]const u8, zone_id: cdb.zone_vnum) u64;
extern fn eq_cancel_owner(owner_kind: c_int, owner_id: i64, tag: ?[*:0]const u8) i64;
extern fn eq_owner_count(owner_kind: c_int, owner_id: i64, tag: ?[*:0]const u8) i64;
extern fn eq_owner_next_ms(owner_kind: c_int, owner_id: i64, tag: ?[*:0]const u8) i64;
extern fn event_queue_now_ms() i64;

const ZoneHandle = extern struct {
    vnum: cdb.zone_vnum,
};

pub fn register(lua: *Lua) void {
    registerZoneMetatable(lua);

    lua.newTable();
    lua.pushFunction(zlua.wrap(luaZoneById));
    lua.setField(-2, "by_id");
    lua.setField(-2, "zones");
}

fn registerZoneMetatable(lua: *Lua) void {
    lua.newMetatable(zone_metatable) catch {
        lua.pop(1);
        return;
    };

    lua.pushValue(-1);
    lua.setField(-2, "__index");

    addMethod(lua, "__tostring", luaZoneToString);
    addMethod(lua, "valid", luaZoneValid);
    addMethod(lua, "is_same", luaZoneIsSame);
    addMethod(lua, "id_get", luaZoneIdGet);
    addMethod(lua, "vnum_get", luaZoneIdGet);
    addMethod(lua, "name_get", luaZoneNameGet);
    addMethod(lua, "send_text", luaZoneSendText);
    addMethod(lua, "event_schedule", luaZoneEventSchedule);
    addMethod(lua, "event_cancel", luaZoneEventCancel);
    addMethod(lua, "event_count", luaZoneEventCount);
    addMethod(lua, "event_remaining_ms", luaZoneEventRemainingMs);

    lua.pop(1);
}

fn addMethod(lua: *Lua, comptime name: [:0]const u8, comptime function: anytype) void {
    lua.pushFunction(zlua.wrap(function));
    lua.setField(-2, name);
}

pub fn pushZone(lua: *Lua, vnum: cdb.zone_vnum) void {
    const handle = lua.newUserdata(ZoneHandle, 0);
    handle.* = .{ .vnum = vnum };
    _ = lua.getMetatableRegistry(zone_metatable);
    lua.setMetatable(-2);
}

fn checkZoneHandle(lua: *Lua) *ZoneHandle {
    return lua.testUserdata(ZoneHandle, 1, zone_metatable) catch {
        lua.raiseErrorStr("expected dbat.Zone", .{});
    };
}

fn checkZone(lua: *Lua) *cdb.zone_data {
    const handle = checkZoneHandle(lua);
    return cdb.zone_by_id(handle.vnum) orelse {
        lua.raiseErrorStr("stale dbat.Zone handle for zone %d", .{handle.vnum});
    };
}

fn luaZoneById(lua: *Lua) i32 {
    const id = lua.toInteger(1) catch {
        lua.pushNil();
        return 1;
    };
    const vnum = std.math.cast(cdb.zone_vnum, id) orelse {
        lua.pushNil();
        return 1;
    };
    if (cdb.zone_by_id(vnum) == null) {
        lua.pushNil();
        return 1;
    }
    pushZone(lua, vnum);
    return 1;
}

fn luaZoneValid(lua: *Lua) i32 {
    const handle = checkZoneHandle(lua);
    lua.pushBoolean(cdb.zone_by_id(handle.vnum) != null);
    return 1;
}

fn luaZoneIsSame(lua: *Lua) i32 {
    const left = checkZoneHandle(lua);
    const right = lua.testUserdata(ZoneHandle, 2, zone_metatable) catch {
        lua.pushBoolean(false);
        return 1;
    };
    lua.pushBoolean(left.vnum == right.vnum);
    return 1;
}

fn luaZoneToString(lua: *Lua) i32 {
    const handle = checkZoneHandle(lua);
    if (cdb.zone_by_id(handle.vnum)) |zone| {
        _ = lua.pushFString("dbat.Zone(%d, %s)", .{ handle.vnum, cdb.zone_name_get(zone) });
    } else {
        _ = lua.pushFString("dbat.Zone(%d, stale)", .{handle.vnum});
    }
    return 1;
}

fn luaZoneIdGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.zone_id_get(checkZone(lua)));
    return 1;
}

fn luaZoneNameGet(lua: *Lua) i32 {
    const name = cdb.zone_name_get(checkZone(lua));
    if (name == null) {
        lua.pushNil();
    } else {
        _ = lua.pushString(std.mem.span(name));
    }
    return 1;
}

fn luaZoneSendText(lua: *Lua) i32 {
    const zone = checkZone(lua);
    const text = lua.toString(2) catch lua.typeError(2, "string");
    cdb.send_to_zone(@constCast(text.ptr), zone);
    return 0;
}

fn luaZoneEventSchedule(lua: *Lua) i32 {
    const zone = checkZone(lua);
    const kind = lua.toString(2) catch lua.typeError(2, "string");
    const delay_ms = lua.toInteger(3) catch lua.typeError(3, "integer");
    const interval_ms: i64 = if (lua.typeOf(4) == .number) @intCast(lua.toInteger(4) catch 0) else 0;
    const vnum = cdb.zone_id_get(zone);
    const now = event_queue_now_ms();
    const id = event_schedule_lua_zone_update(now + delay_ms, interval_ms, kind.ptr, @intCast(vnum));
    lua.pushInteger(@intCast(id));
    return 1;
}

fn luaZoneEventCancel(lua: *Lua) i32 {
    const zone = checkZone(lua);
    const kind = lua.toString(2) catch lua.typeError(2, "string");
    const vnum = cdb.zone_id_get(zone);
    const n = eq_cancel_owner(@as(c_int, cdb.EQ_OWNER_ZONE), vnum, kind.ptr);
    lua.pushInteger(n);
    return 1;
}

fn luaZoneEventCount(lua: *Lua) i32 {
    const zone = checkZone(lua);
    const kind: ?[:0]const u8 = if (lua.typeOf(2) == .string) (lua.toString(2) catch null) else null;
    const ptr: ?[*:0]const u8 = if (kind) |k| k.ptr else null;
    const vnum = cdb.zone_id_get(zone);
    const n = eq_owner_count(@as(c_int, cdb.EQ_OWNER_ZONE), vnum, ptr);
    lua.pushInteger(n);
    return 1;
}

fn luaZoneEventRemainingMs(lua: *Lua) i32 {
    const zone = checkZone(lua);
    const kind: ?[:0]const u8 = if (lua.typeOf(2) == .string) (lua.toString(2) catch null) else null;
    const ptr: ?[*:0]const u8 = if (kind) |k| k.ptr else null;
    const vnum = cdb.zone_id_get(zone);
    const ms = eq_owner_next_ms(@as(c_int, cdb.EQ_OWNER_ZONE), vnum, ptr);
    lua.pushInteger(ms);
    return 1;
}
