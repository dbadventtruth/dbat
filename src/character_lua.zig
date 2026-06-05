const std = @import("std");
const zlua = @import("zlua");
const cdb = @import("cdb");
const objects_lua = @import("object_lua.zig");
const rooms_lua = @import("room_lua.zig");
const zones_lua = @import("zone_lua.zig");
const lua_meta = @import("lua_meta.zig");

const Lua = zlua.Lua;
const character_metatable = "dbat.Character";
const mob_proto_metatable = "dbat.MobPrototype";
const condition_metatable = "dbat.Condition";

const CharacterHandle = extern struct {
    id: i64,
};

const MobProtoHandle = extern struct {
    vnum: cdb.mob_vnum,
};

const ConditionHandle = extern struct {
    character_id: i64,
    condition: [64:0]u8,
};

pub fn register(lua: *Lua) void {
    registerCharacterMetatable(lua);
    registerMobProtoMetatable(lua);
    registerConditionMetatable(lua);

    lua.newTable();
    lua.pushFunction(zlua.wrap(luaCharacterById));
    lua.setField(-2, "by_id");
    lua.pushFunction(zlua.wrap(luaCharactersAll));
    lua.setField(-2, "all");
    lua.setField(-2, "characters");

    lua.newTable();
    lua.pushFunction(zlua.wrap(luaMobProtoById));
    lua.setField(-2, "by_id");
    lua.setField(-2, "mob_protos");
}

fn luaCharacterById(lua: *Lua) i32 {
    const id = lua.toInteger(1) catch {
        lua.pushNil();
        return 1;
    };

    if (cdb.char_by_id(id) == null) {
        lua.pushNil();
        return 1;
    }

    pushCharacter(lua, id);
    return 1;
}

fn luaCharactersAll(lua: *Lua) i32 {
    lua.newTable();
    const iterator = cdb.char_iterator_create();
    defer cdb.char_iterator_free(iterator);

    var index: usize = 1;
    while (cdb.char_next(iterator)) |ch| {
        if (cdb.char_is_extracted(ch)) continue;
        pushCharacter(lua, cdb.char_id_get(ch));
        lua.setIndex(-2, @intCast(index));
        index += 1;
    }

    return valueIterator(lua);
}

fn registerCharacterMetatable(lua: *Lua) void {
    lua.newMetatable(character_metatable) catch {
        lua.pop(1);
        return;
    };

    lua.pushValue(-1);
    lua.setField(-2, "__index");

    addMethod(lua, "__tostring", luaCharacterToString);
    addMethod(lua, "reftype", luaCharacterRefType);
    addMethod(lua, "is_npc", luaCharacterIsNpc);
    addMethod(lua, "valid", luaCharacterValid);
    addMethod(lua, "is_same", luaCharacterIsSame);
    addMethod(lua, "update", luaCharacterUpdate);
    addMethod(lua, "send", luaCharacterSend);
    addMethod(lua, "send_text", luaCharacterSendText);
    addMethod(lua, "extract", luaCharacterExtract);
    addMethod(lua, "can_see_in_dark", luaCharacterCanSeeInDark);
    addMethod(lua, "can_see_char", luaCharacterCanSeeChar);
    addMethod(lua, "can_see_obj", luaCharacterCanSeeObj);
    addMethod(lua, "id_get", luaCharacterIdGet);
    addMethod(lua, "proto_id_get", luaCharacterProtoIdGet);
    addMethod(lua, "proto_id_set", luaCharacterProtoIdSet);
    addMethod(lua, "vnum_get", luaCharacterVnumGet);
    addMethod(lua, "vnum_set", luaCharacterVnumSet);
    addMethod(lua, "room_vnum_get", luaCharacterRoomVnumGet);
    addMethod(lua, "room_vnum_set", luaCharacterRoomVnumSet);
    addMethod(lua, "room_get", luaCharacterRoomGet);
    addMethod(lua, "from_room", luaCharacterFromRoom);
    addMethod(lua, "to_room", luaCharacterToRoom);
    addMethod(lua, "unequip", luaCharacterUnequip);
    addMethod(lua, "zone_vnum_get", luaCharacterZoneVnumGet);
    addMethod(lua, "zone_get", luaCharacterZoneGet);
    addMethod(lua, "reveal_hiding", luaCharacterRevealHiding);
    addMethod(lua, "release_charge", luaCharacterReleaseCharge);
    addMethod(lua, "send_to_sense", luaCharacterSendToSense);
    addMethod(lua, "send_to_scouter", luaCharacterSendToScouter);
    addMethod(lua, "name_get", luaCharacterNameGet);
    addMethod(lua, "name_set", luaCharacterNameSet);
    addMethod(lua, "description_get", luaCharacterDescriptionGet);
    addMethod(lua, "description_set", luaCharacterDescriptionSet);
    addMethod(lua, "short_description_get", luaCharacterShortDescriptionGet);
    addMethod(lua, "short_description_set", luaCharacterShortDescriptionSet);
    addMethod(lua, "long_description_get", luaCharacterLongDescriptionGet);
    addMethod(lua, "long_description_set", luaCharacterLongDescriptionSet);
    addMethod(lua, "title_get", luaCharacterTitleGet);
    addMethod(lua, "title_set", luaCharacterTitleSet);
    addMethod(lua, "sensei_get", luaCharacterSenseiGet);
    addMethod(lua, "sensei_set", luaCharacterSenseiSet);
    addMethod(lua, "race_get", luaCharacterRaceGet);
    addMethod(lua, "race_set", luaCharacterRaceSet);
    addMethod(lua, "size_get", luaCharacterSizeGet);
    addMethod(lua, "size_set", luaCharacterSizeSet);
    addMethod(lua, "size_mod", luaCharacterSizeMod);
    addMethod(lua, "sex_get", luaCharacterSexGet);
    addMethod(lua, "sex_set", luaCharacterSexSet);
    addMethod(lua, "admin_level_get", luaCharacterAdminLevelGet);
    addMethod(lua, "admin_level_set", luaCharacterAdminLevelSet);
    addMethod(lua, "admin_level_mod", luaCharacterAdminLevelMod);
    addMethod(lua, "admin_flagged", luaCharacterAdminFlagged);
    addMethod(lua, "admin_flag_set", luaCharacterAdminFlagSet);
    addMethod(lua, "admin_flag_toggle", luaCharacterAdminFlagToggle);
    addMethod(lua, "player_flagged", luaCharacterPlayerFlagged);
    addMethod(lua, "player_flag_set", luaCharacterPlayerFlagSet);
    addMethod(lua, "player_flag_toggle", luaCharacterPlayerFlagToggle);
    addMethod(lua, "stat_get", luaCharacterStatGet);
    addMethod(lua, "stat_set", luaCharacterStatSet);
    addMethod(lua, "stat_mod", luaCharacterStatMod);
    addMethod(lua, "der_base", luaCharacterDerivedBase);
    addMethod(lua, "der_total", luaCharacterDerivedTotal);
    addMethod(lua, "der_invalidate", luaCharacterDerivedInvalidate);
    addMethod(lua, "meter_get", luaCharacterMeterGet);
    addMethod(lua, "meter_set", luaCharacterMeterSet);
    addMethod(lua, "meter_mod", luaCharacterMeterMod);
    addMethod(lua, "meter_set_int", luaCharacterMeterSetInt);
    addMethod(lua, "meter_mod_int", luaCharacterMeterModInt);
    addMethod(lua, "meter_current", luaCharacterMeterCurrent);
    addMethod(lua, "meter_max", luaCharacterMeterMax);
    addMethod(lua, "skill_base_get", luaCharacterSkillBaseGet);
    addMethod(lua, "skill_base_set", luaCharacterSkillBaseSet);
    addMethod(lua, "skill_base_mod", luaCharacterSkillBaseMod);
    addMethod(lua, "skill_modifier_get", luaCharacterSkillModifierGet);
    addMethod(lua, "skill_total_get", luaCharacterSkillTotalGet);
    addMethod(lua, "skill_get", luaCharacterSkillTotalGet);
    addMethod(lua, "skill_perf_get", luaCharacterSkillPerfGet);
    addMethod(lua, "skill_perf_set", luaCharacterSkillPerfSet);
    addMethod(lua, "skill_perf_mod", luaCharacterSkillPerfMod);
    addMethod(lua, "condition_has", luaCharacterConditionHas);
    addMethod(lua, "condition_has_tag", luaCharacterConditionHasTag);
    addMethod(lua, "condition_active_with_tag", luaCharacterConditionActiveWithTag);
    addMethod(lua, "condition_add", luaCharacterConditionAdd);
    addMethod(lua, "condition_apply", luaCharacterConditionApply);
    addMethod(lua, "condition_apply_variables", luaCharacterConditionApplyVariables);
    addMethod(lua, "condition_apply_number", luaCharacterConditionApplyNumber);
    addMethod(lua, "condition_remove", luaCharacterConditionRemove);
    addMethod(lua, "condition_remove_tag", luaCharacterConditionRemoveTag);
    addMethod(lua, "condition", luaCharacterCondition);
    addMethod(lua, "condition_number_get", luaCharacterConditionNumberGet);
    addMethod(lua, "condition_number_set", luaCharacterConditionNumberSet);
    addMethod(lua, "condition_number_mod", luaCharacterConditionNumberMod);
    addMethod(lua, "condition_string_get", luaCharacterConditionStringGet);
    addMethod(lua, "condition_string_set", luaCharacterConditionStringSet);
    addMethod(lua, "transform_has", luaCharacterTransformHas);
    addMethod(lua, "transform_add", luaCharacterTransformAdd);
    addMethod(lua, "transform_remove", luaCharacterTransformRemove);
    addMethod(lua, "transform_unlocked", luaCharacterTransformUnlocked);
    addMethod(lua, "transform_unlock", luaCharacterTransformUnlock);
    addMethod(lua, "transform_number_get", luaCharacterTransformNumberGet);
    addMethod(lua, "transform_number_set", luaCharacterTransformNumberSet);
    addMethod(lua, "transform_number_mod", luaCharacterTransformNumberMod);
    addMethod(lua, "transform_string_get", luaCharacterTransformStringGet);
    addMethod(lua, "transform_string_set", luaCharacterTransformStringSet);
    addMethod(lua, "inventory_count", luaCharacterInventoryCount);
    addMethod(lua, "equipment_count", luaCharacterEquipmentCount);
    addMethod(lua, "inventory_get", luaCharacterInventoryGet);
    addMethod(lua, "equipment_get", luaCharacterEquipmentGet);
    addMethod(lua, "inventory", luaCharacterInventoryGet);
    addMethod(lua, "equipment", luaCharacterEquipmentGet);

    lua_meta.mergeMethods(lua, "lua.meta.character");

    lua.pop(1);
}

fn registerMobProtoMetatable(lua: *Lua) void {
    lua.newMetatable(mob_proto_metatable) catch {
        lua.pop(1);
        return;
    };

    lua.pushValue(-1);
    lua.setField(-2, "__index");

    addMethod(lua, "__tostring", luaMobProtoToString);
    addMethod(lua, "reftype", luaMobProtoRefType);
    addMethod(lua, "valid", luaMobProtoValid);
    addMethod(lua, "vnum_get", luaMobProtoVnumGet);
    addMethod(lua, "spawn", luaMobProtoSpawn);

    lua.pop(1);
}

fn registerConditionMetatable(lua: *Lua) void {
    lua.newMetatable(condition_metatable) catch {
        lua.pop(1);
        return;
    };
    lua.pushValue(-1);
    lua.setField(-2, "__index");
    addMethod(lua, "id", luaConditionId);
    addMethod(lua, "stacks", luaConditionStacks);
    addMethod(lua, "stacks_set", luaConditionStacksSet);
    addMethod(lua, "duration", luaConditionDuration);
    addMethod(lua, "duration_set", luaConditionDurationSet);
    addMethod(lua, "number_get", luaConditionNumberGet);
    addMethod(lua, "number_set", luaConditionNumberSet);
    addMethod(lua, "number_mod", luaConditionNumberMod);
    addMethod(lua, "string_get", luaConditionStringGet);
    addMethod(lua, "string_set", luaConditionStringSet);
    lua.pop(1);
}

fn addMethod(lua: *Lua, comptime name: [:0]const u8, comptime function: anytype) void {
    lua.pushFunction(zlua.wrap(function));
    lua.setField(-2, name);
}

pub fn pushCharacter(lua: *Lua, id: i64) void {
    const handle = lua.newUserdata(CharacterHandle, 0);
    handle.* = .{ .id = id };
    _ = lua.getMetatableRegistry(character_metatable);
    lua.setMetatable(-2);
}

pub fn pushMobProto(lua: *Lua, vnum: cdb.mob_vnum) void {
    const handle = lua.newUserdata(MobProtoHandle, 0);
    handle.* = .{ .vnum = vnum };
    _ = lua.getMetatableRegistry(mob_proto_metatable);
    lua.setMetatable(-2);
}

pub fn pushCondition(lua: *Lua, character_id: i64, condition: []const u8) void {
    const handle = lua.newUserdata(ConditionHandle, 0);
    handle.character_id = character_id;
    handle.condition = std.mem.zeroes([64:0]u8);
    const len = @min(condition.len, handle.condition.len - 1);
    @memcpy(handle.condition[0..len], condition[0..len]);
    _ = lua.getMetatableRegistry(condition_metatable);
    lua.setMetatable(-2);
}

fn checkCharacterHandle(lua: *Lua) *CharacterHandle {
    return lua.testUserdata(CharacterHandle, 1, character_metatable) catch {
        lua.raiseErrorStr("expected dbat.Character", .{});
    };
}

pub fn checkCharacter(lua: *Lua) *cdb.char_data {
    return checkCharacterAt(lua, 1);
}

pub fn checkCharacterAt(lua: *Lua, index: i32) *cdb.char_data {
    const handle = lua.testUserdata(CharacterHandle, index, character_metatable) catch {
        lua.raiseErrorStr("expected dbat.Character", .{});
    };
    return characterByHandleId(handle.id) orelse {
        lua.raiseErrorStr("stale dbat.Character handle for character %d", .{handle.id});
    };
}

fn characterByHandleId(id: i64) ?*cdb.char_data {
    const ch = cdb.char_by_id(id) orelse return null;
    if (cdb.char_is_extracted(ch)) return null;
    return ch;
}

fn checkMobProtoHandle(lua: *Lua) *MobProtoHandle {
    return lua.testUserdata(MobProtoHandle, 1, mob_proto_metatable) catch {
        lua.raiseErrorStr("expected dbat.MobPrototype", .{});
    };
}

fn checkMobProto(lua: *Lua) *cdb.mob_proto_data {
    const handle = checkMobProtoHandle(lua);
    return cdb.mob_proto_by_id(handle.vnum) orelse {
        lua.raiseErrorStr("stale dbat.MobPrototype handle for mobile prototype %d", .{handle.vnum});
    };
}

fn checkConditionHandle(lua: *Lua) *ConditionHandle {
    return lua.testUserdata(ConditionHandle, 1, condition_metatable) catch {
        lua.raiseErrorStr("expected dbat.Condition", .{});
    };
}

fn conditionCharacter(lua: *Lua, handle: *ConditionHandle) *cdb.char_data {
    return characterByHandleId(handle.character_id) orelse lua.raiseErrorStr("stale dbat.Condition character", .{});
}

fn conditionName(handle: *ConditionHandle) [*:0]const u8 {
    return @ptrCast(&handle.condition);
}

fn integer(lua: *Lua, index: i32) zlua.Integer {
    return lua.toInteger(index) catch lua.typeError(index, "integer");
}

fn boolean(lua: *Lua, index: i32) bool {
    if (!lua.isBoolean(index)) lua.typeError(index, "boolean");
    return lua.toBoolean(index);
}

fn string(lua: *Lua, index: i32) [:0]const u8 {
    return lua.toString(index) catch lua.typeError(index, "string");
}

fn pushCString(lua: *Lua, value: [*c]const u8) void {
    if (value == null) {
        lua.pushNil();
        return;
    }
    _ = lua.pushString(std.mem.span(value));
}

fn intCastOrError(lua: *Lua, comptime T: type, value: zlua.Integer, label: [:0]const u8) T {
    return std.math.cast(T, value) orelse lua.raiseErrorStr("%s out of range", .{label.ptr});
}

fn legacyForDefinitionId(lua: *Lua, comptime category: [:0]const u8, id: [:0]const u8) ?c_int {
    const top = lua.getTop();
    defer lua.setTop(top);

    if (lua.getGlobal("dbat") != .table) return null;
    if (lua.getField(-1, "registry") != .table) return null;
    if (lua.getField(-1, category) != .table) return null;
    if (lua.getField(-1, id) != .table) return null;
    if (lua.getField(-1, "legacy_id") != .number) return null;
    const legacy_id = lua.toInteger(-1) catch return null;
    return std.math.cast(c_int, legacy_id) orelse null;
}

fn pushDefinitionIdForLegacy(lua: *Lua, comptime category: [:0]const u8, legacy_id: c_int) bool {
    const top = lua.getTop();
    var id_buf: [128]u8 = undefined;
    var id_len: usize = 0;
    var found = false;

    if (lua.getGlobal("dbat") == .table and
        lua.getField(-1, "registry") == .table and
        lua.getField(-1, category) == .table)
    {
        lua.pushNil();
        while (lua.next(-2)) {
            defer lua.pop(1);
            if (!lua.isTable(-1)) continue;
            if (lua.getField(-1, "legacy_id") != .number) {
                lua.pop(1);
                continue;
            }
            const value = lua.toInteger(-1) catch blk: {
                lua.pop(1);
                break :blk null;
            };
            lua.pop(1);
            if (value == null or value.? != legacy_id) continue;
            if (lua.getField(-1, "id") != .string) {
                lua.pop(1);
                continue;
            }
            const id = lua.toString(-1) catch "";
            lua.pop(1);
            id_len = @min(id.len, id_buf.len);
            @memcpy(id_buf[0..id_len], id[0..id_len]);
            found = true;
            break;
        }
    }

    lua.setTop(top);
    if (!found) return false;
    _ = lua.pushString(id_buf[0..id_len]);
    return true;
}

fn luaCharacterIsNpc(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    lua.pushBoolean(cdb.char_is_npc(ch));
    return 1;
}

fn luaCharacterValid(lua: *Lua) i32 {
    const handle = checkCharacterHandle(lua);
    lua.pushBoolean(characterByHandleId(handle.id) != null);
    return 1;
}

fn luaCharacterIsSame(lua: *Lua) i32 {
    const left = checkCharacterHandle(lua);
    const right = lua.testUserdata(CharacterHandle, 2, character_metatable) catch {
        lua.pushBoolean(false);
        return 1;
    };
    lua.pushBoolean(left.id == right.id);
    return 1;
}

fn luaCharacterUpdate(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const kind = if (lua.isNoneOrNil(2)) "manual" else string(lua, 2);
    const seconds: i64 = if (lua.isNoneOrNil(3)) 0 else intCastOrError(lua, i64, integer(lua, 3), "update seconds");
    cdb.char_condition_update_with_context(ch, kind, 0, seconds);
    return 0;
}

fn luaCharacterToString(lua: *Lua) i32 {
    const handle = checkCharacterHandle(lua);
    if (characterByHandleId(handle.id)) |ch| {
        _ = lua.pushFString("dbat.Character(%d, %s)", .{ handle.id, cdb.char_name_get(ch) });
    } else {
        _ = lua.pushFString("dbat.Character(%d, stale)", .{handle.id});
    }
    return 1;
}

fn luaCharacterRefType(lua: *Lua) i32 {
    _ = checkCharacter(lua);
    _ = lua.pushString("character");
    return 1;
}

fn luaCharacterSend(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    if (ch.desc != null) cdb.desc_send_text(ch.desc, string(lua, 2));
    return 0;
}

fn luaCharacterSendText(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const text = string(lua, 2);
    _ = cdb.send_to_char(ch, "%s", text.ptr);
    return 0;
}

fn luaCharacterExtract(lua: *Lua) i32 {
    cdb.extract_char(checkCharacter(lua));
    return 0;
}

fn luaCharacterCanSeeInDark(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_can_see_in_dark(checkCharacter(lua)));
    return 1;
}

fn luaCharacterCanSeeChar(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_can_see_char(checkCharacter(lua), checkCharacterAt(lua, 2)));
    return 1;
}

fn luaCharacterCanSeeObj(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_can_see_obj(checkCharacter(lua), objects_lua.checkObjectAt(lua, 2)));
    return 1;
}

fn luaCharacterIdGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_id_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterProtoIdGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_proto_id_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterProtoIdSet(lua: *Lua) i32 {
    cdb.char_proto_id_set(checkCharacter(lua), intCastOrError(lua, cdb.mob_vnum, integer(lua, 2), "mobile proto id"));
    return 0;
}

fn luaCharacterVnumGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_vnum_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterVnumSet(lua: *Lua) i32 {
    cdb.char_vnum_set(checkCharacter(lua), intCastOrError(lua, cdb.mob_vnum, integer(lua, 2), "mobile vnum"));
    return 0;
}

fn luaCharacterRoomVnumGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_room_vnum_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterRoomVnumSet(lua: *Lua) i32 {
    cdb.char_room_vnum_set(checkCharacter(lua), intCastOrError(lua, cdb.room_vnum, integer(lua, 2), "room vnum"));
    return 0;
}

fn luaCharacterRoomGet(lua: *Lua) i32 {
    const room = cdb.char_room_get(checkCharacter(lua));
    if (room == null) {
        lua.pushNil();
        return 1;
    }
    rooms_lua.pushRoom(lua, room.*.number);
    return 1;
}

fn luaCharacterFromRoom(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    if (cdb.char_room_get(ch) != null) cdb.char_from_room(ch);
    return 0;
}

fn luaCharacterToRoom(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const room = rooms_lua.checkRoomAt(lua, 2);
    if (cdb.char_room_get(ch) != null) cdb.char_from_room(ch);
    cdb.char_to_room(ch, room);
    return 0;
}

fn luaCharacterUnequip(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const pos = intCastOrError(lua, c_int, integer(lua, 2), "equipment position");
    const obj = cdb.unequip_char(ch, pos);
    if (obj == null) {
        lua.pushNil();
        return 1;
    }
    objects_lua.pushObject(lua, cdb.obj_id_get(obj));
    return 1;
}

fn luaMobProtoById(lua: *Lua) i32 {
    const vnum = lua.toInteger(1) catch {
        lua.pushNil();
        return 1;
    };
    const mob_vnum = std.math.cast(cdb.mob_vnum, vnum) orelse {
        lua.pushNil();
        return 1;
    };
    if (cdb.mob_proto_by_id(mob_vnum) == null) {
        lua.pushNil();
        return 1;
    }
    pushMobProto(lua, mob_vnum);
    return 1;
}

fn luaMobProtoToString(lua: *Lua) i32 {
    const handle = checkMobProtoHandle(lua);
    _ = checkMobProto(lua);
    _ = lua.pushFString("dbat.MobPrototype(%d)", .{handle.vnum});
    return 1;
}

fn luaMobProtoRefType(lua: *Lua) i32 {
    _ = checkMobProto(lua);
    _ = lua.pushString("mob_prototype");
    return 1;
}

fn luaMobProtoValid(lua: *Lua) i32 {
    const handle = checkMobProtoHandle(lua);
    lua.pushBoolean(cdb.mob_proto_by_id(handle.vnum) != null);
    return 1;
}

fn luaMobProtoVnumGet(lua: *Lua) i32 {
    lua.pushInteger(checkMobProtoHandle(lua).vnum);
    return 1;
}

fn luaMobProtoSpawn(lua: *Lua) i32 {
    const handle = checkMobProtoHandle(lua);
    _ = checkMobProto(lua);
    const mob = cdb.mob_spawn(handle.vnum);
    if (mob == null) {
        lua.pushNil();
        return 1;
    }

    if (!lua.isNoneOrNil(2)) {
        const room = rooms_lua.checkRoomAt(lua, 2);
        cdb.char_to_room(mob, room);
    }

    pushCharacter(lua, cdb.char_id_get(mob));
    return 1;
}

fn luaCharacterZoneVnumGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_zone_vnum_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterZoneGet(lua: *Lua) i32 {
    const zone = cdb.char_zone_get(checkCharacter(lua));
    if (zone == null) {
        lua.pushNil();
        return 1;
    }
    zones_lua.pushZone(lua, cdb.zone_id_get(zone));
    return 1;
}

fn luaCharacterRevealHiding(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const reveal_type = if (lua.getTop() >= 2) intCastOrError(lua, c_int, integer(lua, 2), "reveal type") else 0;
    cdb.reveal_hiding(ch, reveal_type);
    return 0;
}

fn luaCharacterReleaseCharge(lua: *Lua) i32 {
    lua.pushBoolean(cdb.release_charge(checkCharacter(lua)));
    return 1;
}

fn luaCharacterSendToSense(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const sense_type = intCastOrError(lua, c_int, integer(lua, 2), "sense type");
    const text = string(lua, 3);
    cdb.send_to_sense(sense_type, @constCast(text.ptr), ch);
    return 0;
}

fn luaCharacterSendToScouter(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const text = string(lua, 2);
    const num = if (lua.getTop() >= 3) intCastOrError(lua, c_int, integer(lua, 3), "scouter num") else 1;
    const scouter_type = if (lua.getTop() >= 4) intCastOrError(lua, c_int, integer(lua, 4), "scouter type") else 0;
    cdb.send_to_scouter(@constCast(text.ptr), ch, num, scouter_type);
    return 0;
}

fn luaCharacterNameGet(lua: *Lua) i32 {
    pushCString(lua, cdb.char_name_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterNameSet(lua: *Lua) i32 {
    cdb.char_name_set(checkCharacter(lua), string(lua, 2));
    return 0;
}

fn luaCharacterDescriptionGet(lua: *Lua) i32 {
    pushCString(lua, cdb.char_description_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterDescriptionSet(lua: *Lua) i32 {
    cdb.char_description_set(checkCharacter(lua), string(lua, 2));
    return 0;
}

fn luaCharacterShortDescriptionGet(lua: *Lua) i32 {
    pushCString(lua, cdb.char_short_description_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterShortDescriptionSet(lua: *Lua) i32 {
    cdb.char_short_description_set(checkCharacter(lua), string(lua, 2));
    return 0;
}

fn luaCharacterLongDescriptionGet(lua: *Lua) i32 {
    pushCString(lua, cdb.char_long_description_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterLongDescriptionSet(lua: *Lua) i32 {
    cdb.char_long_description_set(checkCharacter(lua), string(lua, 2));
    return 0;
}

fn luaCharacterTitleGet(lua: *Lua) i32 {
    pushCString(lua, cdb.char_title_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterTitleSet(lua: *Lua) i32 {
    cdb.char_title_set(checkCharacter(lua), string(lua, 2));
    return 0;
}

fn luaCharacterSenseiGet(lua: *Lua) i32 {
    const legacy_id = cdb.char_class_get(checkCharacter(lua));
    if (!pushDefinitionIdForLegacy(lua, "senseis", legacy_id)) lua.pushNil();
    return 1;
}

fn luaCharacterSenseiSet(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const id = string(lua, 2);
    const legacy_id = legacyForDefinitionId(lua, "senseis", id) orelse lua.raiseErrorStr("unknown sensei '%s'", .{id.ptr});
    cdb.char_class_set(ch, legacy_id);
    return 0;
}

fn luaCharacterRaceGet(lua: *Lua) i32 {
    const legacy_id = cdb.char_race_get(checkCharacter(lua));
    if (!pushDefinitionIdForLegacy(lua, "races", legacy_id)) lua.pushNil();
    return 1;
}

fn luaCharacterRaceSet(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const id = string(lua, 2);
    const legacy_id = legacyForDefinitionId(lua, "races", id) orelse lua.raiseErrorStr("unknown race '%s'", .{id.ptr});
    cdb.char_race_set(ch, legacy_id);
    return 0;
}

fn luaCharacterSizeGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_size_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterSizeSet(lua: *Lua) i32 {
    cdb.char_size_set(checkCharacter(lua), intCastOrError(lua, c_int, integer(lua, 2), "size"));
    return 0;
}

fn luaCharacterSizeMod(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const value = cdb.char_size_get(ch) + intCastOrError(lua, c_int, integer(lua, 2), "size delta");
    cdb.char_size_set(ch, value);
    lua.pushInteger(value);
    return 1;
}

fn luaCharacterSexGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_sex_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterSexSet(lua: *Lua) i32 {
    cdb.char_sex_set(checkCharacter(lua), intCastOrError(lua, c_int, integer(lua, 2), "sex"));
    return 0;
}

fn luaCharacterAdminLevelGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_admlevel_get(checkCharacter(lua)));
    return 1;
}

fn luaCharacterAdminLevelSet(lua: *Lua) i32 {
    cdb.char_admlevel_set(checkCharacter(lua), intCastOrError(lua, c_int, integer(lua, 2), "admin level"));
    return 0;
}

fn luaCharacterAdminLevelMod(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const value = cdb.char_admlevel_get(ch) + intCastOrError(lua, c_int, integer(lua, 2), "admin level delta");
    cdb.char_admlevel_set(ch, value);
    lua.pushInteger(value);
    return 1;
}

fn luaCharacterAdminFlagged(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_admflagged(checkCharacter(lua), intCastOrError(lua, c_int, integer(lua, 2), "admin flag")));
    return 1;
}

fn luaCharacterAdminFlagSet(lua: *Lua) i32 {
    cdb.char_admflag_set(checkCharacter(lua), intCastOrError(lua, c_int, integer(lua, 2), "admin flag"), boolean(lua, 3));
    return 0;
}

fn luaCharacterAdminFlagToggle(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_admflag_toggle(checkCharacter(lua), intCastOrError(lua, c_int, integer(lua, 2), "admin flag")));
    return 1;
}

fn luaCharacterPlayerFlagged(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_plrflagged(checkCharacter(lua), intCastOrError(lua, c_int, integer(lua, 2), "player flag")));
    return 1;
}

fn luaCharacterPlayerFlagSet(lua: *Lua) i32 {
    cdb.char_plrflag_set(checkCharacter(lua), intCastOrError(lua, c_int, integer(lua, 2), "player flag"), boolean(lua, 3));
    return 0;
}

fn luaCharacterPlayerFlagToggle(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_plrflag_toggle(checkCharacter(lua), intCastOrError(lua, c_int, integer(lua, 2), "player flag")));
    return 1;
}

fn luaCharacterStatGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_stat_get(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterStatSet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_stat_set(checkCharacter(lua), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "stat value")));
    return 1;
}

fn luaCharacterStatMod(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_stat_mod(checkCharacter(lua), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "stat delta")));
    return 1;
}

fn luaCharacterDerivedBase(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_der_base_get(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterDerivedTotal(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_der_total_get(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterDerivedInvalidate(lua: *Lua) i32 {
    cdb.char_der_invalidate(checkCharacter(lua));
    return 0;
}

fn luaCharacterMeterGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_meter_get(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterMeterSet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_meter_set(checkCharacter(lua), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "meter value")));
    return 1;
}

fn luaCharacterMeterMod(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_meter_mod(checkCharacter(lua), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "meter delta")));
    return 1;
}

fn luaCharacterMeterSetInt(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_meter_set_int(checkCharacter(lua), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "meter current")));
    return 1;
}

fn luaCharacterMeterModInt(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_meter_mod_int(checkCharacter(lua), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "meter current delta")));
    return 1;
}

fn luaCharacterMeterCurrent(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_meter_current(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterMeterMax(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_meter_max(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterSkillBaseGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_skill_base_get(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterSkillBaseSet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_skill_base_set(checkCharacter(lua), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "skill base")));
    return 1;
}

fn luaCharacterSkillBaseMod(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_skill_base_mod(checkCharacter(lua), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "skill base delta")));
    return 1;
}

fn luaCharacterSkillModifierGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_skill_modifier_get(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterSkillTotalGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_skill_total_get(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterSkillPerfGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_skill_perf_get(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterSkillPerfSet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_skill_perf_set(checkCharacter(lua), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "skill performance")));
    return 1;
}

fn luaCharacterSkillPerfMod(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_skill_perf_mod(checkCharacter(lua), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "skill performance delta")));
    return 1;
}

fn luaCharacterConditionHas(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_condition_has(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterConditionHasTag(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_condition_has_tag(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterConditionActiveWithTag(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const condition = cdb.char_condition_active_with_tag(ch, string(lua, 2));
    if (condition == null) {
        lua.pushNil();
        return 1;
    }
    pushCondition(lua, cdb.char_id_get(ch), std.mem.span(condition));
    return 1;
}

fn luaCharacterConditionAdd(lua: *Lua) i32 {
    const source_category = if (lua.isNoneOrNil(3)) "lua" else string(lua, 3);
    const source_id = if (lua.isNoneOrNil(4)) "unknown" else string(lua, 4);
    lua.pushBoolean(cdb.char_condition_add(checkCharacter(lua), string(lua, 2), source_category, source_id));
    return 1;
}

fn luaCharacterConditionApply(lua: *Lua) i32 {
    const source_category = if (lua.isNoneOrNil(3)) "lua" else string(lua, 3);
    const source_id = if (lua.isNoneOrNil(4)) "unknown" else string(lua, 4);
    lua.pushBoolean(cdb.char_condition_apply(checkCharacter(lua), string(lua, 2), source_category, source_id));
    return 1;
}

fn luaCharacterConditionApplyVariables(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const condition = string(lua, 2);
    var numbers = collectNumberArgs(lua, 3);
    defer numbers.deinit();
    var strings = collectStringArgs(lua, 4);
    defer strings.deinit();
    const source_category = if (lua.isNoneOrNil(5)) "lua" else string(lua, 5);
    const source_id = if (lua.isNoneOrNil(6)) "unknown" else string(lua, 6);
    lua.pushBoolean(cdb.char_condition_apply_with_variables(ch, condition, source_category, source_id, numbers.items.ptr, numbers.items.len, strings.items.ptr, strings.items.len));
    return 1;
}

fn luaCharacterConditionApplyNumber(lua: *Lua) i32 {
    const source_category = if (lua.isNoneOrNil(5)) "lua" else string(lua, 5);
    const source_id = if (lua.isNoneOrNil(6)) "unknown" else string(lua, 6);
    lua.pushBoolean(cdb.char_condition_apply_with_number(checkCharacter(lua), string(lua, 2), source_category, source_id, string(lua, 3), intCastOrError(lua, i64, integer(lua, 4), "condition number")));
    return 1;
}

fn luaCharacterConditionRemove(lua: *Lua) i32 {
    const reason = if (lua.isNoneOrNil(3)) "removed" else string(lua, 3);
    lua.pushBoolean(cdb.char_condition_remove(checkCharacter(lua), string(lua, 2), reason));
    return 1;
}

fn collectNumberArgs(lua: *Lua, index: i32) std.array_list.Managed(cdb.condition_number_arg) {
    var result = std.array_list.Managed(cdb.condition_number_arg).init(std.heap.page_allocator);
    if (lua.isNoneOrNil(index)) return result;
    if (!lua.isTable(index)) lua.typeError(index, "table");

    lua.pushNil();
    while (lua.next(index)) {
        const key = lua.toString(-2) catch {
            lua.pop(1);
            continue;
        };
        const value = lua.toInteger(-1) catch {
            lua.pop(1);
            continue;
        };
        result.append(.{ .key = @ptrCast(key.ptr), .value = intCastOrError(lua, i64, value, "condition number") }) catch lua.raiseErrorStr("out of memory", .{});
        lua.pop(1);
    }
    return result;
}

fn collectStringArgs(lua: *Lua, index: i32) std.array_list.Managed(cdb.condition_string_arg) {
    var result = std.array_list.Managed(cdb.condition_string_arg).init(std.heap.page_allocator);
    if (lua.isNoneOrNil(index)) return result;
    if (!lua.isTable(index)) lua.typeError(index, "table");

    lua.pushNil();
    while (lua.next(index)) {
        const key = lua.toString(-2) catch {
            lua.pop(1);
            continue;
        };
        const value = lua.toString(-1) catch {
            lua.pop(1);
            continue;
        };
        result.append(.{ .key = @ptrCast(key.ptr), .value = @ptrCast(value.ptr) }) catch lua.raiseErrorStr("out of memory", .{});
        lua.pop(1);
    }
    return result;
}

fn luaCharacterConditionRemoveTag(lua: *Lua) i32 {
    const reason = if (lua.isNoneOrNil(3)) "removed" else string(lua, 3);
    lua.pushInteger(cdb.char_condition_remove_tag(checkCharacter(lua), string(lua, 2), reason));
    return 1;
}

fn luaCharacterCondition(lua: *Lua) i32 {
    const ch = checkCharacter(lua);
    const condition = string(lua, 2);
    if (!cdb.char_condition_has(ch, condition)) {
        lua.pushNil();
        return 1;
    }
    pushCondition(lua, cdb.char_id_get(ch), condition);
    return 1;
}

fn luaCharacterConditionNumberGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_condition_number_get(checkCharacter(lua), string(lua, 2), string(lua, 3)));
    return 1;
}

fn luaCharacterConditionNumberSet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_condition_number_set(checkCharacter(lua), string(lua, 2), string(lua, 3), intCastOrError(lua, i64, integer(lua, 4), "condition number")));
    return 1;
}

fn luaCharacterConditionNumberMod(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_condition_number_mod(checkCharacter(lua), string(lua, 2), string(lua, 3), intCastOrError(lua, i64, integer(lua, 4), "condition number delta")));
    return 1;
}

fn luaCharacterConditionStringGet(lua: *Lua) i32 {
    pushCString(lua, cdb.char_condition_string_get(checkCharacter(lua), string(lua, 2), string(lua, 3)));
    return 1;
}

fn luaCharacterConditionStringSet(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_condition_string_set(checkCharacter(lua), string(lua, 2), string(lua, 3), string(lua, 4)));
    return 1;
}

fn luaCharacterTransformHas(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_transform_has(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterTransformAdd(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_transform_add(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterTransformRemove(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_transform_remove(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterTransformUnlocked(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_transform_unlocked(checkCharacter(lua), string(lua, 2)));
    return 1;
}

fn luaCharacterTransformUnlock(lua: *Lua) i32 {
    const source = if (lua.isNoneOrNil(3)) "lua" else string(lua, 3);
    lua.pushBoolean(cdb.char_transform_unlock(checkCharacter(lua), string(lua, 2), source));
    return 1;
}

fn luaCharacterTransformNumberGet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_transform_number_get(checkCharacter(lua), string(lua, 2), string(lua, 3)));
    return 1;
}

fn luaCharacterTransformNumberSet(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_transform_number_set(checkCharacter(lua), string(lua, 2), string(lua, 3), intCastOrError(lua, i64, integer(lua, 4), "transform number")));
    return 1;
}

fn luaCharacterTransformNumberMod(lua: *Lua) i32 {
    lua.pushInteger(cdb.char_transform_number_mod(checkCharacter(lua), string(lua, 2), string(lua, 3), intCastOrError(lua, i64, integer(lua, 4), "transform number delta")));
    return 1;
}

fn luaCharacterTransformStringGet(lua: *Lua) i32 {
    pushCString(lua, cdb.char_transform_string_get(checkCharacter(lua), string(lua, 2), string(lua, 3)));
    return 1;
}

fn luaCharacterTransformStringSet(lua: *Lua) i32 {
    lua.pushBoolean(cdb.char_transform_string_set(checkCharacter(lua), string(lua, 2), string(lua, 3), string(lua, 4)));
    return 1;
}

fn luaConditionId(lua: *Lua) i32 {
    _ = lua.pushString(std.mem.span(conditionName(checkConditionHandle(lua))));
    return 1;
}

fn luaConditionStacks(lua: *Lua) i32 {
    const handle = checkConditionHandle(lua);
    lua.pushInteger(cdb.char_condition_stacks_get(conditionCharacter(lua, handle), conditionName(handle)));
    return 1;
}

fn luaConditionStacksSet(lua: *Lua) i32 {
    const handle = checkConditionHandle(lua);
    lua.pushInteger(cdb.char_condition_stacks_set(conditionCharacter(lua, handle), conditionName(handle), intCastOrError(lua, i64, integer(lua, 2), "condition stacks")));
    return 1;
}

fn luaConditionDuration(lua: *Lua) i32 {
    const handle = checkConditionHandle(lua);
    lua.pushInteger(cdb.char_condition_duration_get(conditionCharacter(lua, handle), conditionName(handle)));
    return 1;
}

fn luaConditionDurationSet(lua: *Lua) i32 {
    const handle = checkConditionHandle(lua);
    lua.pushInteger(cdb.char_condition_duration_set(conditionCharacter(lua, handle), conditionName(handle), intCastOrError(lua, i64, integer(lua, 2), "condition duration")));
    return 1;
}

fn luaConditionNumberGet(lua: *Lua) i32 {
    const handle = checkConditionHandle(lua);
    lua.pushInteger(cdb.char_condition_number_get(conditionCharacter(lua, handle), conditionName(handle), string(lua, 2)));
    return 1;
}

fn luaConditionNumberSet(lua: *Lua) i32 {
    const handle = checkConditionHandle(lua);
    lua.pushInteger(cdb.char_condition_number_set(conditionCharacter(lua, handle), conditionName(handle), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "condition number")));
    return 1;
}

fn luaConditionNumberMod(lua: *Lua) i32 {
    const handle = checkConditionHandle(lua);
    lua.pushInteger(cdb.char_condition_number_mod(conditionCharacter(lua, handle), conditionName(handle), string(lua, 2), intCastOrError(lua, i64, integer(lua, 3), "condition number delta")));
    return 1;
}

fn luaConditionStringGet(lua: *Lua) i32 {
    const handle = checkConditionHandle(lua);
    pushCString(lua, cdb.char_condition_string_get(conditionCharacter(lua, handle), conditionName(handle), string(lua, 2)));
    return 1;
}

fn luaConditionStringSet(lua: *Lua) i32 {
    const handle = checkConditionHandle(lua);
    lua.pushBoolean(cdb.char_condition_string_set(conditionCharacter(lua, handle), conditionName(handle), string(lua, 2), string(lua, 3)));
    return 1;
}

fn luaCharacterInventoryCount(lua: *Lua) i32 {
    const recursive = if (lua.isNoneOrNil(2)) false else boolean(lua, 2);
    lua.pushInteger(@intCast(cdb.char_inventory_count(checkCharacter(lua), recursive)));
    return 1;
}

fn luaCharacterEquipmentCount(lua: *Lua) i32 {
    const recursive = if (lua.isNoneOrNil(2)) false else boolean(lua, 2);
    lua.pushInteger(@intCast(cdb.char_equipment_count(checkCharacter(lua), recursive)));
    return 1;
}

fn luaCharacterInventoryGet(lua: *Lua) i32 {
    if (lua.isNoneOrNil(2)) return pushInventoryIterator(lua, checkCharacter(lua));

    const obj = cdb.char_inventory_get(checkCharacter(lua), intCastOrError(lua, usize, integer(lua, 2), "inventory index"));
    if (obj == null) {
        lua.pushNil();
        return 1;
    }
    objects_lua.pushObject(lua, cdb.obj_id_get(obj));
    return 1;
}

fn luaCharacterEquipmentGet(lua: *Lua) i32 {
    if (lua.isNoneOrNil(2)) return pushEquipmentIterator(lua, checkCharacter(lua));

    const obj = cdb.char_equipment_get(checkCharacter(lua), intCastOrError(lua, usize, integer(lua, 2), "equipment index"));
    if (obj == null) {
        lua.pushNil();
        return 1;
    }
    objects_lua.pushObject(lua, cdb.obj_id_get(obj));
    return 1;
}

fn pushInventoryIterator(lua: *Lua, ch: *cdb.char_data) i32 {
    lua.newTable();
    var pos: usize = 0;
    while (true) : (pos += 1) {
        const obj = cdb.char_inventory_get(ch, pos);
        if (obj == null) break;
        objects_lua.pushObject(lua, cdb.obj_id_get(obj));
        lua.setIndex(-2, @intCast(pos + 1));
    }
    return valueIterator(lua);
}

fn pushEquipmentIterator(lua: *Lua, ch: *cdb.char_data) i32 {
    lua.newTable();
    var pos: usize = 0;
    while (true) : (pos += 1) {
        const obj = cdb.char_equipment_get(ch, pos);
        if (pos >= cdb.NUM_WEARS) break;
        if (obj == null) continue;
        objects_lua.pushObject(lua, cdb.obj_id_get(obj));
        lua.setIndex(-2, @intCast(pos));
    }
    return pairsIterator(lua);
}

fn valueIterator(lua: *Lua) i32 {
    _ = lua.getGlobal("dbat");
    _ = lua.getField(-1, "_values");
    lua.remove(-2);
    lua.insert(-2);
    lua.protectedCall(.{ .args = 1, .results = 1 }) catch lua.raiseErrorStr("failed to create value iterator", .{});
    return 1;
}

fn pairsIterator(lua: *Lua) i32 {
    _ = lua.getGlobal("pairs");
    lua.insert(-2);
    lua.protectedCall(.{ .args = 1, .results = 3 }) catch lua.raiseErrorStr("failed to create pairs iterator", .{});
    return 3;
}
