const std = @import("std");
const zlua = @import("zlua");
const cdb = @import("cdb");
const characters_lua = @import("character_lua.zig");
const objects_lua = @import("object_lua.zig");
const rooms_lua = @import("room_lua.zig");

const Lua = zlua.Lua;

// Mob triggers
extern fn act_mtrigger(ch: *cdb.char_data, str: [*c]u8, actor: ?*cdb.char_data, victim: ?*const cdb.char_data, object: ?*cdb.obj_data, target: ?*const cdb.obj_data, arg: [*c]const u8) void;
extern fn speech_mtrigger(actor: *cdb.char_data, str: [*c]u8) void;
extern fn greet_memory_mtrigger(ch: *cdb.char_data) void;
extern fn greet_mtrigger(actor: *cdb.char_data, dir: c_int) c_int;
extern fn entry_mtrigger(ch: *cdb.char_data) c_int;
extern fn entry_memory_mtrigger(ch: *cdb.char_data) void;
extern fn command_mtrigger(actor: *cdb.char_data, cmd: [*c]u8, argument: [*c]u8) c_int;
extern fn bribe_mtrigger(ch: *cdb.char_data, actor: *cdb.char_data, amount: c_int) void;
extern fn receive_mtrigger(ch: *cdb.char_data, actor: *cdb.char_data, obj: *cdb.obj_data) c_int;
extern fn fight_mtrigger(ch: *cdb.char_data) void;
extern fn hitprcnt_mtrigger(ch: *cdb.char_data) void;
extern fn death_mtrigger(ch: *cdb.char_data, actor: ?*cdb.char_data) c_int;
extern fn random_mtrigger(ch: *cdb.char_data) void;
extern fn load_mtrigger(ch: *cdb.char_data) void;
extern fn cast_mtrigger(actor: *cdb.char_data, ch: *cdb.char_data, spellnum: c_int) c_int;
extern fn leave_mtrigger(actor: *cdb.char_data, dir: c_int) c_int;
extern fn door_mtrigger(actor: *cdb.char_data, subcmd: c_int, dir: c_int) c_int;
extern fn time_mtrigger(ch: *cdb.char_data) void;

// Object triggers
extern fn random_otrigger(obj: *cdb.obj_data) void;
extern fn timer_otrigger(obj: *cdb.obj_data) void;
extern fn get_otrigger(obj: *cdb.obj_data, actor: *cdb.char_data) c_int;
extern fn command_otrigger(actor: *cdb.char_data, cmd: [*c]u8, argument: [*c]u8) c_int;
extern fn drop_otrigger(obj: *cdb.obj_data, actor: *cdb.char_data) c_int;
extern fn give_otrigger(obj: *cdb.obj_data, actor: *cdb.char_data, victim: *cdb.char_data) c_int;
extern fn wear_otrigger(obj: *cdb.obj_data, actor: *cdb.char_data, where: c_int) c_int;
extern fn remove_otrigger(obj: *cdb.obj_data, actor: *cdb.char_data) c_int;
extern fn load_otrigger(obj: *cdb.obj_data) void;
extern fn cast_otrigger(actor: *cdb.char_data, obj: *cdb.obj_data, spellnum: c_int) c_int;
extern fn leave_otrigger(room: *cdb.room_data, actor: *cdb.char_data, dir: c_int) c_int;
extern fn consume_otrigger(obj: *cdb.obj_data, actor: *cdb.char_data, cmd: c_int) c_int;
extern fn time_otrigger(obj: *cdb.obj_data) void;

// World triggers
extern fn reset_wtrigger(room: *cdb.room_data) void;
extern fn random_wtrigger(room: *cdb.room_data) void;
extern fn enter_wtrigger(room: *cdb.room_data, actor: *cdb.char_data, dir: c_int) c_int;
extern fn speech_wtrigger(actor: *cdb.char_data, str: [*c]u8) void;
extern fn command_wtrigger(actor: *cdb.char_data, cmd: [*c]u8, argument: [*c]u8) c_int;
extern fn drop_wtrigger(obj: *cdb.obj_data, actor: *cdb.char_data) c_int;
extern fn cast_wtrigger(actor: *cdb.char_data, vict: ?*cdb.char_data, obj: ?*cdb.obj_data, spellnum: c_int) c_int;
extern fn leave_wtrigger(room: *cdb.room_data, actor: *cdb.char_data, dir: c_int) c_int;
extern fn door_wtrigger(actor: *cdb.char_data, subcmd: c_int, dir: c_int) c_int;
extern fn time_wtrigger(room: *cdb.room_data) void;

// ── helpers ──────────────────────────────────────────────────────────────────

fn str(lua: *Lua, index: i32) [:0]const u8 {
    return lua.toString(index) catch lua.typeError(index, "string");
}

fn mutableStr(lua: *Lua, index: i32) [*c]u8 {
    // The DG trigger functions accept char*, but only read from them in practice.
    // We cast away const from the Lua-owned buffer here.
    const s = str(lua, index);
    return @constCast(s.ptr);
}

// ── mob trigger wrappers ─────────────────────────────────────────────────────

fn luaActMtrigger(lua: *Lua) i32 {
    const ch = characters_lua.checkCharacterAt(lua, 1);
    const s = mutableStr(lua, 2);
    const actor: ?*cdb.char_data = if (lua.isNoneOrNil(3)) null else characters_lua.checkCharacterAt(lua, 3);
    const victim: ?*const cdb.char_data = if (lua.isNoneOrNil(4)) null else characters_lua.checkCharacterAt(lua, 4);
    const object: ?*cdb.obj_data = if (lua.isNoneOrNil(5)) null else objects_lua.checkObjectAt(lua, 5);
    const target: ?*const cdb.obj_data = if (lua.isNoneOrNil(6)) null else objects_lua.checkObjectAt(lua, 6);
    const arg: [*c]const u8 = if (lua.isNoneOrNil(7)) null else str(lua, 7).ptr;
    act_mtrigger(ch, s, actor, victim, object, target, arg);
    return 0;
}

fn luaSpeechMtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const s = mutableStr(lua, 2);
    speech_mtrigger(actor, s);
    return 0;
}

fn luaGreetMemoryMtrigger(lua: *Lua) i32 {
    greet_memory_mtrigger(characters_lua.checkCharacterAt(lua, 1));
    return 0;
}

fn luaGreetMtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const dir = lua.toInteger(2) catch lua.typeError(2, "integer");
    lua.pushBoolean(greet_mtrigger(actor, @intCast(dir)) != 0);
    return 1;
}

fn luaEntryMtrigger(lua: *Lua) i32 {
    lua.pushBoolean(entry_mtrigger(characters_lua.checkCharacterAt(lua, 1)) != 0);
    return 1;
}

fn luaEntryMemoryMtrigger(lua: *Lua) i32 {
    entry_memory_mtrigger(characters_lua.checkCharacterAt(lua, 1));
    return 0;
}

fn luaCommandMtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const cmd = mutableStr(lua, 2);
    const argument = mutableStr(lua, 3);
    lua.pushBoolean(command_mtrigger(actor, cmd, argument) != 0);
    return 1;
}

fn luaBribeMtrigger(lua: *Lua) i32 {
    const ch = characters_lua.checkCharacterAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    const amount = lua.toInteger(3) catch lua.typeError(3, "integer");
    bribe_mtrigger(ch, actor, @intCast(amount));
    return 0;
}

fn luaReceiveMtrigger(lua: *Lua) i32 {
    const ch = characters_lua.checkCharacterAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    const obj = objects_lua.checkObjectAt(lua, 3);
    lua.pushBoolean(receive_mtrigger(ch, actor, obj) != 0);
    return 1;
}

fn luaFightMtrigger(lua: *Lua) i32 {
    fight_mtrigger(characters_lua.checkCharacterAt(lua, 1));
    return 0;
}

fn luaHitprcntMtrigger(lua: *Lua) i32 {
    hitprcnt_mtrigger(characters_lua.checkCharacterAt(lua, 1));
    return 0;
}

fn luaDeathMtrigger(lua: *Lua) i32 {
    const ch = characters_lua.checkCharacterAt(lua, 1);
    const actor: ?*cdb.char_data = if (lua.isNoneOrNil(2)) null else characters_lua.checkCharacterAt(lua, 2);
    lua.pushBoolean(death_mtrigger(ch, actor) != 0);
    return 1;
}

fn luaRandomMtrigger(lua: *Lua) i32 {
    random_mtrigger(characters_lua.checkCharacterAt(lua, 1));
    return 0;
}

fn luaLoadMtrigger(lua: *Lua) i32 {
    load_mtrigger(characters_lua.checkCharacterAt(lua, 1));
    return 0;
}

fn luaCastMtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const ch = characters_lua.checkCharacterAt(lua, 2);
    const spellnum = lua.toInteger(3) catch lua.typeError(3, "integer");
    lua.pushBoolean(cast_mtrigger(actor, ch, @intCast(spellnum)) != 0);
    return 1;
}

fn luaLeaveMtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const dir = lua.toInteger(2) catch lua.typeError(2, "integer");
    lua.pushBoolean(leave_mtrigger(actor, @intCast(dir)) != 0);
    return 1;
}

fn luaDoorMtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const subcmd = lua.toInteger(2) catch lua.typeError(2, "integer");
    const dir = lua.toInteger(3) catch lua.typeError(3, "integer");
    lua.pushBoolean(door_mtrigger(actor, @intCast(subcmd), @intCast(dir)) != 0);
    return 1;
}

fn luaTimeMtrigger(lua: *Lua) i32 {
    time_mtrigger(characters_lua.checkCharacterAt(lua, 1));
    return 0;
}

// ── object trigger wrappers ──────────────────────────────────────────────────

fn luaRandomOtrigger(lua: *Lua) i32 {
    random_otrigger(objects_lua.checkObjectAt(lua, 1));
    return 0;
}

fn luaTimerOtrigger(lua: *Lua) i32 {
    timer_otrigger(objects_lua.checkObjectAt(lua, 1));
    return 0;
}

fn luaGetOtrigger(lua: *Lua) i32 {
    const obj = objects_lua.checkObjectAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    lua.pushBoolean(get_otrigger(obj, actor) != 0);
    return 1;
}

fn luaCommandOtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const cmd = mutableStr(lua, 2);
    const argument = mutableStr(lua, 3);
    lua.pushBoolean(command_otrigger(actor, cmd, argument) != 0);
    return 1;
}

fn luaDropOtrigger(lua: *Lua) i32 {
    const obj = objects_lua.checkObjectAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    lua.pushBoolean(drop_otrigger(obj, actor) != 0);
    return 1;
}

fn luaGiveOtrigger(lua: *Lua) i32 {
    const obj = objects_lua.checkObjectAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    const victim = characters_lua.checkCharacterAt(lua, 3);
    lua.pushBoolean(give_otrigger(obj, actor, victim) != 0);
    return 1;
}

fn luaWearOtrigger(lua: *Lua) i32 {
    const obj = objects_lua.checkObjectAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    const where = lua.toInteger(3) catch lua.typeError(3, "integer");
    lua.pushBoolean(wear_otrigger(obj, actor, @intCast(where)) != 0);
    return 1;
}

fn luaRemoveOtrigger(lua: *Lua) i32 {
    const obj = objects_lua.checkObjectAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    lua.pushBoolean(remove_otrigger(obj, actor) != 0);
    return 1;
}

fn luaLoadOtrigger(lua: *Lua) i32 {
    load_otrigger(objects_lua.checkObjectAt(lua, 1));
    return 0;
}

fn luaCastOtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const obj = objects_lua.checkObjectAt(lua, 2);
    const spellnum = lua.toInteger(3) catch lua.typeError(3, "integer");
    lua.pushBoolean(cast_otrigger(actor, obj, @intCast(spellnum)) != 0);
    return 1;
}

fn luaLeaveOtrigger(lua: *Lua) i32 {
    const room = rooms_lua.checkRoomAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    const dir = lua.toInteger(3) catch lua.typeError(3, "integer");
    lua.pushBoolean(leave_otrigger(room, actor, @intCast(dir)) != 0);
    return 1;
}

fn luaConsumeOtrigger(lua: *Lua) i32 {
    const obj = objects_lua.checkObjectAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    const cmd = lua.toInteger(3) catch lua.typeError(3, "integer");
    lua.pushBoolean(consume_otrigger(obj, actor, @intCast(cmd)) != 0);
    return 1;
}

fn luaTimeOtrigger(lua: *Lua) i32 {
    time_otrigger(objects_lua.checkObjectAt(lua, 1));
    return 0;
}

// ── world trigger wrappers ───────────────────────────────────────────────────

fn luaResetWtrigger(lua: *Lua) i32 {
    reset_wtrigger(rooms_lua.checkRoomAt(lua, 1));
    return 0;
}

fn luaRandomWtrigger(lua: *Lua) i32 {
    random_wtrigger(rooms_lua.checkRoomAt(lua, 1));
    return 0;
}

fn luaEnterWtrigger(lua: *Lua) i32 {
    const room = rooms_lua.checkRoomAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    const dir = lua.toInteger(3) catch lua.typeError(3, "integer");
    lua.pushBoolean(enter_wtrigger(room, actor, @intCast(dir)) != 0);
    return 1;
}

fn luaSpeechWtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const s = mutableStr(lua, 2);
    speech_wtrigger(actor, s);
    return 0;
}

fn luaCommandWtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const cmd = mutableStr(lua, 2);
    const argument = mutableStr(lua, 3);
    lua.pushBoolean(command_wtrigger(actor, cmd, argument) != 0);
    return 1;
}

fn luaDropWtrigger(lua: *Lua) i32 {
    const obj = objects_lua.checkObjectAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    lua.pushBoolean(drop_wtrigger(obj, actor) != 0);
    return 1;
}

fn luaCastWtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const vict: ?*cdb.char_data = if (lua.isNoneOrNil(2)) null else characters_lua.checkCharacterAt(lua, 2);
    const obj: ?*cdb.obj_data = if (lua.isNoneOrNil(3)) null else objects_lua.checkObjectAt(lua, 3);
    const spellnum = lua.toInteger(4) catch lua.typeError(4, "integer");
    lua.pushBoolean(cast_wtrigger(actor, vict, obj, @intCast(spellnum)) != 0);
    return 1;
}

fn luaLeaveWtrigger(lua: *Lua) i32 {
    const room = rooms_lua.checkRoomAt(lua, 1);
    const actor = characters_lua.checkCharacterAt(lua, 2);
    const dir = lua.toInteger(3) catch lua.typeError(3, "integer");
    lua.pushBoolean(leave_wtrigger(room, actor, @intCast(dir)) != 0);
    return 1;
}

fn luaDoorWtrigger(lua: *Lua) i32 {
    const actor = characters_lua.checkCharacterAt(lua, 1);
    const subcmd = lua.toInteger(2) catch lua.typeError(2, "integer");
    const dir = lua.toInteger(3) catch lua.typeError(3, "integer");
    lua.pushBoolean(door_wtrigger(actor, @intCast(subcmd), @intCast(dir)) != 0);
    return 1;
}

fn luaTimeWtrigger(lua: *Lua) i32 {
    time_wtrigger(rooms_lua.checkRoomAt(lua, 1));
    return 0;
}

// ── registration ─────────────────────────────────────────────────────────────

pub fn register(lua: *Lua) void {
    lua.newTable();

    // mob triggers
    lua.pushFunction(zlua.wrap(luaActMtrigger));
    lua.setField(-2, "act_mtrigger");
    lua.pushFunction(zlua.wrap(luaSpeechMtrigger));
    lua.setField(-2, "speech_mtrigger");
    lua.pushFunction(zlua.wrap(luaGreetMemoryMtrigger));
    lua.setField(-2, "greet_memory_mtrigger");
    lua.pushFunction(zlua.wrap(luaGreetMtrigger));
    lua.setField(-2, "greet_mtrigger");
    lua.pushFunction(zlua.wrap(luaEntryMtrigger));
    lua.setField(-2, "entry_mtrigger");
    lua.pushFunction(zlua.wrap(luaEntryMemoryMtrigger));
    lua.setField(-2, "entry_memory_mtrigger");
    lua.pushFunction(zlua.wrap(luaCommandMtrigger));
    lua.setField(-2, "command_mtrigger");
    lua.pushFunction(zlua.wrap(luaBribeMtrigger));
    lua.setField(-2, "bribe_mtrigger");
    lua.pushFunction(zlua.wrap(luaReceiveMtrigger));
    lua.setField(-2, "receive_mtrigger");
    lua.pushFunction(zlua.wrap(luaFightMtrigger));
    lua.setField(-2, "fight_mtrigger");
    lua.pushFunction(zlua.wrap(luaHitprcntMtrigger));
    lua.setField(-2, "hitprcnt_mtrigger");
    lua.pushFunction(zlua.wrap(luaDeathMtrigger));
    lua.setField(-2, "death_mtrigger");
    lua.pushFunction(zlua.wrap(luaRandomMtrigger));
    lua.setField(-2, "random_mtrigger");
    lua.pushFunction(zlua.wrap(luaLoadMtrigger));
    lua.setField(-2, "load_mtrigger");
    lua.pushFunction(zlua.wrap(luaCastMtrigger));
    lua.setField(-2, "cast_mtrigger");
    lua.pushFunction(zlua.wrap(luaLeaveMtrigger));
    lua.setField(-2, "leave_mtrigger");
    lua.pushFunction(zlua.wrap(luaDoorMtrigger));
    lua.setField(-2, "door_mtrigger");
    lua.pushFunction(zlua.wrap(luaTimeMtrigger));
    lua.setField(-2, "time_mtrigger");

    // object triggers
    lua.pushFunction(zlua.wrap(luaRandomOtrigger));
    lua.setField(-2, "random_otrigger");
    lua.pushFunction(zlua.wrap(luaTimerOtrigger));
    lua.setField(-2, "timer_otrigger");
    lua.pushFunction(zlua.wrap(luaGetOtrigger));
    lua.setField(-2, "get_otrigger");
    lua.pushFunction(zlua.wrap(luaCommandOtrigger));
    lua.setField(-2, "command_otrigger");
    lua.pushFunction(zlua.wrap(luaDropOtrigger));
    lua.setField(-2, "drop_otrigger");
    lua.pushFunction(zlua.wrap(luaGiveOtrigger));
    lua.setField(-2, "give_otrigger");
    lua.pushFunction(zlua.wrap(luaWearOtrigger));
    lua.setField(-2, "wear_otrigger");
    lua.pushFunction(zlua.wrap(luaRemoveOtrigger));
    lua.setField(-2, "remove_otrigger");
    lua.pushFunction(zlua.wrap(luaLoadOtrigger));
    lua.setField(-2, "load_otrigger");
    lua.pushFunction(zlua.wrap(luaCastOtrigger));
    lua.setField(-2, "cast_otrigger");
    lua.pushFunction(zlua.wrap(luaLeaveOtrigger));
    lua.setField(-2, "leave_otrigger");
    lua.pushFunction(zlua.wrap(luaConsumeOtrigger));
    lua.setField(-2, "consume_otrigger");
    lua.pushFunction(zlua.wrap(luaTimeOtrigger));
    lua.setField(-2, "time_otrigger");

    // world triggers
    lua.pushFunction(zlua.wrap(luaResetWtrigger));
    lua.setField(-2, "reset_wtrigger");
    lua.pushFunction(zlua.wrap(luaRandomWtrigger));
    lua.setField(-2, "random_wtrigger");
    lua.pushFunction(zlua.wrap(luaEnterWtrigger));
    lua.setField(-2, "enter_wtrigger");
    lua.pushFunction(zlua.wrap(luaSpeechWtrigger));
    lua.setField(-2, "speech_wtrigger");
    lua.pushFunction(zlua.wrap(luaCommandWtrigger));
    lua.setField(-2, "command_wtrigger");
    lua.pushFunction(zlua.wrap(luaDropWtrigger));
    lua.setField(-2, "drop_wtrigger");
    lua.pushFunction(zlua.wrap(luaCastWtrigger));
    lua.setField(-2, "cast_wtrigger");
    lua.pushFunction(zlua.wrap(luaLeaveWtrigger));
    lua.setField(-2, "leave_wtrigger");
    lua.pushFunction(zlua.wrap(luaDoorWtrigger));
    lua.setField(-2, "door_wtrigger");
    lua.pushFunction(zlua.wrap(luaTimeWtrigger));
    lua.setField(-2, "time_wtrigger");

    lua.setField(-2, "dgscripts");
}
