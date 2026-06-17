const std = @import("std");
const zlua = @import("zlua");
const cdb = @import("cdb");
const characters_lua = @import("character_lua.zig");
const objects_lua = @import("object_lua.zig");
const lua_meta = @import("lua_meta.zig");

const Lua = zlua.Lua;
const room_metatable = "dbat.Room";

extern fn event_schedule_lua_room_update(fire_at: i64, interval: i64, kind: ?[*:0]const u8, room_id: cdb.room_vnum) u64;
extern fn eq_cancel_owner(owner_kind: c_int, owner_id: i64, tag: ?[*:0]const u8) i64;
extern fn eq_owner_count(owner_kind: c_int, owner_id: i64, tag: ?[*:0]const u8) i64;
extern fn eq_owner_next_ms(owner_kind: c_int, owner_id: i64, tag: ?[*:0]const u8) i64;
extern fn event_queue_now_ms() i64;

const RoomHandle = extern struct {
    vnum: cdb.room_vnum,
};

pub fn register(lua: *Lua) void {
    registerRoomMetatable(lua);

    lua.newTable();
    lua.pushFunction(zlua.wrap(luaRoomById));
    lua.setField(-2, "by_id");
    lua.setField(-2, "rooms");
}

fn luaRoomById(lua: *Lua) i32 {
    const vnum = lua.toInteger(1) catch {
        lua.pushNil();
        return 1;
    };
    const room_vnum = std.math.cast(cdb.room_vnum, vnum) orelse {
        lua.pushNil();
        return 1;
    };

    if (cdb.room_by_id(room_vnum) == null) {
        lua.pushNil();
        return 1;
    }

    pushRoom(lua, room_vnum);
    return 1;
}

fn registerRoomMetatable(lua: *Lua) void {
    lua.newMetatable(room_metatable) catch {
        lua.pop(1);
        return;
    };

    lua.pushValue(-1);
    lua.setField(-2, "__index");

    lua.pushFunction(zlua.wrap(luaRoomToString));
    lua.setField(-2, "__tostring");

    lua.pushFunction(zlua.wrap(luaRoomRefType));
    lua.setField(-2, "reftype");

    lua.pushFunction(zlua.wrap(luaRoomValid));
    lua.setField(-2, "valid");
    lua.pushFunction(zlua.wrap(luaRoomIsSame));
    lua.setField(-2, "is_same");
    lua.pushFunction(zlua.wrap(luaRoomIsDark));
    lua.setField(-2, "is_dark");
    lua.pushFunction(zlua.wrap(luaRoomIsSunken));
    lua.setField(-2, "is_sunken");
    lua.pushFunction(zlua.wrap(luaRoomFlagged));
    lua.setField(-2, "flagged");
    lua.pushFunction(zlua.wrap(luaRoomFlagSet));
    lua.setField(-2, "flag_set");
    lua.pushFunction(zlua.wrap(luaRoomFlagToggle));
    lua.setField(-2, "flag_toggle");
    lua.pushFunction(zlua.wrap(luaRoomCookElement));
    lua.setField(-2, "cook_element");
    lua.pushFunction(zlua.wrap(luaRoomIdGet));
    lua.setField(-2, "id_get");
    lua.pushFunction(zlua.wrap(luaRoomVnumGet));
    lua.setField(-2, "vnum_get");
    lua.pushFunction(zlua.wrap(luaRoomNameGet));
    lua.setField(-2, "name_get");
    lua.pushFunction(zlua.wrap(luaRoomNameSet));
    lua.setField(-2, "name_set");
    lua.pushFunction(zlua.wrap(luaRoomDescriptionGet));
    lua.setField(-2, "description_get");
    lua.pushFunction(zlua.wrap(luaRoomDescriptionSet));
    lua.setField(-2, "description_set");
    lua.pushFunction(zlua.wrap(luaRoomSectorTypeGet));
    lua.setField(-2, "sector_type_get");
    lua.pushFunction(zlua.wrap(luaRoomSectorTypeSet));
    lua.setField(-2, "sector_type_set");
    lua.pushFunction(zlua.wrap(luaRoomZoneVnumGet));
    lua.setField(-2, "zone_vnum_get");
    lua.pushFunction(zlua.wrap(luaRoomLightGet));
    lua.setField(-2, "light_get");
    lua.pushFunction(zlua.wrap(luaRoomLightSet));
    lua.setField(-2, "light_set");
    lua.pushFunction(zlua.wrap(luaRoomDamageGet));
    lua.setField(-2, "damage_get");
    lua.pushFunction(zlua.wrap(luaRoomDamageSet));
    lua.setField(-2, "damage_set");
    lua.pushFunction(zlua.wrap(luaRoomGravityGet));
    lua.setField(-2, "gravity_get");
    lua.pushFunction(zlua.wrap(luaRoomGravitySet));
    lua.setField(-2, "gravity_set");
    lua.pushFunction(zlua.wrap(luaRoomGeffectGet));
    lua.setField(-2, "geffect_get");
    lua.pushFunction(zlua.wrap(luaRoomGeffectSet));
    lua.setField(-2, "geffect_set");
    lua.pushFunction(zlua.wrap(luaRoomContentsGet));
    lua.setField(-2, "contents_get");
    lua.pushFunction(zlua.wrap(luaRoomContentsGet));
    lua.setField(-2, "contents");
    lua.pushFunction(zlua.wrap(luaRoomPeopleGet));
    lua.setField(-2, "people_get");
    lua.pushFunction(zlua.wrap(luaRoomPeopleGet));
    lua.setField(-2, "people");
    lua.pushFunction(zlua.wrap(luaRoomEventSchedule));
    lua.setField(-2, "event_schedule");
    lua.pushFunction(zlua.wrap(luaRoomEventCancel));
    lua.setField(-2, "event_cancel");
    lua.pushFunction(zlua.wrap(luaRoomEventCount));
    lua.setField(-2, "event_count");
    lua.pushFunction(zlua.wrap(luaRoomEventRemainingMs));
    lua.setField(-2, "event_remaining_ms");

    lua_meta.mergeMethods(lua, "lua.rooms.room");

    lua.pop(1);
}

pub fn pushRoom(lua: *Lua, vnum: cdb.room_vnum) void {
    const handle = lua.newUserdata(RoomHandle, 0);
    handle.* = .{ .vnum = vnum };
    _ = lua.getMetatableRegistry(room_metatable);
    lua.setMetatable(-2);
}

fn checkRoomHandle(lua: *Lua) *RoomHandle {
    return checkRoomHandleAt(lua, 1);
}

pub fn checkRoomHandleAt(lua: *Lua, index: i32) *RoomHandle {
    return lua.testUserdata(RoomHandle, index, room_metatable) catch {
        lua.raiseErrorStr("expected dbat.Room", .{});
    };
}

pub fn checkRoomAt(lua: *Lua, index: i32) *cdb.room_data {
    const handle = checkRoomHandleAt(lua, index);
    return cdb.room_by_id(handle.vnum) orelse {
        lua.raiseErrorStr("stale dbat.Room handle for room %d", .{handle.vnum});
    };
}

pub fn checkRoom(lua: *Lua) *cdb.room_data {
    return checkRoomAt(lua, 1);
}

fn luaRoomValid(lua: *Lua) i32 {
    const handle = checkRoomHandle(lua);
    lua.pushBoolean(cdb.room_by_id(handle.vnum) != null);
    return 1;
}

fn luaRoomIsSame(lua: *Lua) i32 {
    const left = checkRoomHandle(lua);
    const right = lua.testUserdata(RoomHandle, 2, room_metatable) catch {
        lua.pushBoolean(false);
        return 1;
    };
    lua.pushBoolean(left.vnum == right.vnum);
    return 1;
}

fn luaRoomIsDark(lua: *Lua) i32 {
    lua.pushBoolean(cdb.room_is_dark(checkRoom(lua)));
    return 1;
}

fn luaRoomIsSunken(lua: *Lua) i32 {
    lua.pushBoolean(cdb.room_is_sunken(checkRoom(lua)));
    return 1;
}

fn luaRoomFlagged(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const pos = lua.toInteger(2) catch lua.typeError(2, "integer");
    lua.pushBoolean(cdb.room_flagged(room, @intCast(pos)) != 0);
    return 1;
}

fn luaRoomFlagSet(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const pos = lua.toInteger(2) catch lua.typeError(2, "integer");
    const value = lua.toBoolean(3);
    cdb.room_flag_set(room, @intCast(pos), value);
    return 0;
}

fn luaRoomFlagToggle(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const pos = lua.toInteger(2) catch lua.typeError(2, "integer");
    lua.pushBoolean(cdb.room_flag_toggle(room, @intCast(pos)));
    return 1;
}

fn luaRoomCookElement(lua: *Lua) i32 {
    lua.pushInteger(@intFromBool(cdb.cook_element(checkRoom(lua))));
    return 1;
}

fn luaRoomToString(lua: *Lua) i32 {
    const handle = checkRoomHandle(lua);
    if (cdb.room_by_id(handle.vnum)) |room| {
        _ = lua.pushFString("dbat.Room(%d, %s)", .{ handle.vnum, cdb.room_name_get(room) });
    } else {
        _ = lua.pushFString("dbat.Room(%d, stale)", .{handle.vnum});
    }
    return 1;
}

fn luaRoomRefType(lua: *Lua) i32 {
    _ = checkRoom(lua);
    _ = lua.pushString("room");
    return 1;
}

fn luaRoomIdGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.room_id_get(checkRoom(lua)));
    return 1;
}

fn luaRoomVnumGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.room_vnum_get(checkRoom(lua)));
    return 1;
}

fn luaRoomNameGet(lua: *Lua) i32 {
    _ = lua.pushString(std.mem.span(cdb.room_name_get(checkRoom(lua))));
    return 1;
}

fn luaRoomNameSet(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const name = lua.toString(2) catch lua.typeError(2, "string");
    cdb.room_name_set(room, name);
    return 0;
}

fn luaRoomDescriptionGet(lua: *Lua) i32 {
    _ = lua.pushString(std.mem.span(cdb.room_description_get(checkRoom(lua))));
    return 1;
}

fn luaRoomDescriptionSet(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const description = lua.toString(2) catch lua.typeError(2, "string");
    cdb.room_description_set(room, description);
    return 0;
}

fn luaRoomSectorTypeGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.room_sector_type_get(checkRoom(lua)));
    return 1;
}

fn luaRoomSectorTypeSet(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const sector = lua.toInteger(2) catch lua.typeError(2, "integer");
    cdb.room_sector_type_set(room, @intCast(sector));
    return 0;
}

fn luaRoomZoneVnumGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.room_zone_vnum_get(checkRoom(lua)));
    return 1;
}

fn luaRoomLightGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.room_light_get(checkRoom(lua)));
    return 1;
}

fn luaRoomLightSet(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const light = lua.toInteger(2) catch lua.typeError(2, "integer");
    const value = std.math.cast(u16, light) orelse lua.raiseErrorStr("room light out of range", .{});
    cdb.room_light_set(room, value);
    return 0;
}

fn luaRoomDamageGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.room_dmg_get(checkRoom(lua)));
    return 1;
}

fn luaRoomDamageSet(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const damage = lua.toInteger(2) catch lua.typeError(2, "integer");
    cdb.room_dmg_set(room, @intCast(damage));
    return 0;
}

fn luaRoomGravityGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.room_gravity_get(checkRoom(lua)));
    return 1;
}

fn luaRoomGravitySet(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const gravity = lua.toInteger(2) catch lua.typeError(2, "integer");
    cdb.room_gravity_set(room, @intCast(gravity));
    return 0;
}

fn luaRoomGeffectGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.room_geffect_get(checkRoom(lua)));
    return 1;
}

fn luaRoomGeffectSet(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const geffect = lua.toInteger(2) catch lua.typeError(2, "integer");
    cdb.room_geffect_set(room, @intCast(geffect));
    return 0;
}

fn luaRoomContentsGet(lua: *Lua) i32 {
    const room = checkRoom(lua);

    var count: usize = 0;
    const ids = cdb.room_objects_get(room, &count);
    defer if (ids) |_| std.c.free(@as(?*anyopaque, @ptrCast(ids)));

    lua.newTable();
    for (0..count) |i| {
        if (ids) |ptr| {
            objects_lua.pushObject(lua, ptr[i]);
            lua.setIndex(-2, @intCast(i + 1));
        }
    }
    return valueIterator(lua);
}

fn luaRoomPeopleGet(lua: *Lua) i32 {
    const room = checkRoom(lua);
    lua.newTable();

    var count: usize = 0;
    const ids = cdb.room_person_ids(room, &count);
    var index: usize = 1;
    if (ids) |id_list| {
        defer cdb.room_person_ids_free(id_list);
        for (id_list[0..count]) |id| {
            const ch = cdb.char_by_id(id) orelse continue;
            characters_lua.pushCharacter(lua, cdb.char_id_get(ch));
            lua.setIndex(-2, @intCast(index));
            index += 1;
        }
    }

    return valueIterator(lua);
}

fn valueIterator(lua: *Lua) i32 {
    _ = lua.getGlobal("dbat");
    _ = lua.getField(-1, "_values");
    lua.remove(-2);
    lua.insert(-2);
    lua.protectedCall(.{ .args = 1, .results = 1 }) catch lua.raiseErrorStr("failed to create value iterator", .{});
    return 1;
}

fn luaRoomEventSchedule(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const kind = lua.toString(2) catch lua.typeError(2, "string");
    const delay_ms = lua.toInteger(3) catch lua.typeError(3, "integer");
    const interval_ms: i64 = if (lua.typeOf(4) == .number) @intCast(lua.toInteger(4) catch 0) else 0;
    const vnum = cdb.room_vnum_get(room);
    const now = event_queue_now_ms();
    const id = event_schedule_lua_room_update(now + delay_ms, interval_ms, kind.ptr, vnum);
    lua.pushInteger(@intCast(id));
    return 1;
}

fn luaRoomEventCancel(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const kind = lua.toString(2) catch lua.typeError(2, "string");
    const vnum = cdb.room_vnum_get(room);
    const n = eq_cancel_owner(@as(c_int, cdb.EQ_OWNER_ROOM), @as(i64, vnum), kind.ptr);
    lua.pushInteger(n);
    return 1;
}

fn luaRoomEventCount(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const kind: ?[:0]const u8 = if (lua.typeOf(2) == .string) (lua.toString(2) catch null) else null;
    const ptr: ?[*:0]const u8 = if (kind) |k| k.ptr else null;
    const vnum = cdb.room_vnum_get(room);
    const n = eq_owner_count(@as(c_int, cdb.EQ_OWNER_ROOM), @as(i64, vnum), ptr);
    lua.pushInteger(n);
    return 1;
}

fn luaRoomEventRemainingMs(lua: *Lua) i32 {
    const room = checkRoom(lua);
    const kind: ?[:0]const u8 = if (lua.typeOf(2) == .string) (lua.toString(2) catch null) else null;
    const ptr: ?[*:0]const u8 = if (kind) |k| k.ptr else null;
    const vnum = cdb.room_vnum_get(room);
    const ms = eq_owner_next_ms(@as(c_int, cdb.EQ_OWNER_ROOM), @as(i64, vnum), ptr);
    lua.pushInteger(ms);
    return 1;
}
