const std = @import("std");
const cdb = @import("cdb");
const lua_api = @import("lua_api.zig");
const characters_lua = @import("character_lua.zig");
const rooms_lua = @import("room_lua.zig");
const objects_lua = @import("object_lua.zig");
const event_queue = @import("event_queue.zig");


var io: std.Io = undefined;
var has_io = false;
var active_players: usize = 0;

const tick = std.Io.Duration.fromMilliseconds(100);

pub fn init(runtime_io: std.Io) void {
    io = runtime_io;
    active_players = 0;
    has_io = true;
}

pub fn deinit() void {
    active_players = 0;
    has_io = false;
}

pub export fn game_loop() void {
    var next_tick_ns = nowNs() + tick.nanoseconds;
    while (cdb.circle_shutdown == 0) {
        const before_wait_ns = nowNs();
        const now_ms = nowMs();

        // Drain any events that are due before waiting for I/O.
        event_queue.process(now_ms);

        // Sleep until the earlier of: next 100ms tick, or next queued event.
        const tick_wait_ms = waitUntilMs(before_wait_ns, next_tick_ns);
        const event_wait_ms: c_int = if (event_queue.peekDeadline()) |dl|
            @intCast(@max(0, @min(tick_wait_ms, dl - now_ms)))
        else
            tick_wait_ms;

        if (cdb.net_wait(event_wait_ms) < 0) {
            std.Io.sleep(io, .fromMilliseconds(@intCast(event_wait_ms)), .awake) catch {};
        }

        _ = cdb.net_accept_all_pending();
        _ = cdb.net_read_all_pending();
        cdb.game_legacy_process_commands();

        cdb.extract_pending_chars();

        const current_ns = nowNs();
        if (active_players == 0) {
            next_tick_ns = current_ns + tick.nanoseconds;
        } else if (current_ns >= next_tick_ns) {
            const late_ns = current_ns - next_tick_ns;
            if (late_ns >= std.time.ns_per_s) {
                cdb.mud_log("SYSERR: Missed %d seconds worth of pulses.", @as(c_int, @intCast(@divTrunc(late_ns, std.time.ns_per_s))));
            }
            next_tick_ns = current_ns + tick.nanoseconds;
            cdb.pulse += 1;
            heartbeat(@intCast(cdb.pulse));
        }

        cdb.extract_pending_chars();

        cdb.game_legacy_send_outputs();
        _ = cdb.net_flush_all_outputs();
        cdb.game_legacy_close_pending();

        cdb.game_legacy_post_tick();
    }
}

fn nowNs() i96 {
    return std.Io.Timestamp.now(io, .awake).nanoseconds;
}

fn nowMs() i64 {
    return @intCast(@divTrunc(nowNs(), std.time.ns_per_ms));
}

fn waitUntilMs(now_ns: i96, deadline_ns: i96) c_int {
    if (now_ns >= deadline_ns) return 0;
    const remaining = deadline_ns - now_ns;
    if (remaining <= 0) return 0;
    return @intCast(@max(@as(i96, 1), @divTrunc(remaining, std.time.ns_per_ms)));
}

pub export fn heartbeat(heart_pulse: c_int) void {
    cdb.heartbeat_legacy(heart_pulse);
}

pub export fn game_active_player_enter() void {
    active_players += 1;
}

pub export fn game_active_player_leave() void {
    if (active_players > 0) active_players -= 1;
}

pub export fn game_active_player_count() c_int {
    return @intCast(@min(active_players, @as(usize, @intCast(std.math.maxInt(c_int)))));
}

// --- Lua heartbeat hook helpers ---

fn charCall(ch: *cdb.char_data, method: [:0]const u8, pulse: ?c_int) void {
    const lua = lua_api.state();
    const top = lua.getTop();
    defer lua.setTop(top);
    characters_lua.pushCharacter(lua, cdb.char_id_get(ch));
    if (lua.getField(-1, method) != .function) return;
    characters_lua.pushCharacter(lua, cdb.char_id_get(ch));
    if (pulse) |p| lua.pushInteger(p);
    const nargs: i32 = if (pulse != null) 2 else 1;
    lua.protectedCall(.{ .args = nargs, .results = 0 }) catch |err| {
        const message = lua.toString(-1) catch @errorName(err);
        std.log.err("char {s} failed: {s}", .{ method, message });
        lua.pop(1);
    };
}

fn roomCall(room: *cdb.room_data, method: [:0]const u8, pulse: ?c_int) void {
    const lua = lua_api.state();
    const top = lua.getTop();
    defer lua.setTop(top);
    rooms_lua.pushRoom(lua, cdb.room_vnum_get(room));
    if (lua.getField(-1, method) != .function) return;
    rooms_lua.pushRoom(lua, cdb.room_vnum_get(room));
    if (pulse) |p| lua.pushInteger(p);
    const nargs: i32 = if (pulse != null) 2 else 1;
    lua.protectedCall(.{ .args = nargs, .results = 0 }) catch |err| {
        const message = lua.toString(-1) catch @errorName(err);
        std.log.err("room {s} failed: {s}", .{ method, message });
        lua.pop(1);
    };
}

fn objCall(obj: *cdb.obj_data, method: [:0]const u8, pulse: ?c_int) void {
    const lua = lua_api.state();
    const top = lua.getTop();
    defer lua.setTop(top);
    objects_lua.pushObject(lua, cdb.obj_id_get(obj));
    if (lua.getField(-1, method) != .function) return;
    objects_lua.pushObject(lua, cdb.obj_id_get(obj));
    if (pulse) |p| lua.pushInteger(p);
    const nargs: i32 = if (pulse != null) 2 else 1;
    lua.protectedCall(.{ .args = nargs, .results = 0 }) catch |err| {
        const message = lua.toString(-1) catch @errorName(err);
        std.log.err("obj {s} failed: {s}", .{ method, message });
        lua.pop(1);
    };
}

// --- C-exposed entity hooks (caller iterates) ---

pub export fn char_on_second(ch: *cdb.char_data) void {
    if (cdb.char_is_extracted(ch)) return;
    charCall(ch, "on_second", null);
}

pub export fn char_on_mud_hour(ch: *cdb.char_data) void {
    if (cdb.char_is_extracted(ch)) return;
    charCall(ch, "on_mud_hour", null);
}

pub export fn char_on_heartbeat(ch: *cdb.char_data, pulse: c_int) void {
    if (cdb.char_is_extracted(ch)) return;
    charCall(ch, "on_heartbeat", pulse);
}

pub export fn room_on_second(room: *cdb.room_data) void {
    roomCall(room, "on_second", null);
}

pub export fn room_on_mud_hour(room: *cdb.room_data) void {
    roomCall(room, "on_mud_hour", null);
}

pub export fn room_on_heartbeat(room: *cdb.room_data, pulse: c_int) void {
    roomCall(room, "on_heartbeat", pulse);
}

pub export fn obj_on_second(obj: *cdb.obj_data) void {
    objCall(obj, "on_second", null);
}

pub export fn obj_on_mud_hour(obj: *cdb.obj_data) void {
    objCall(obj, "on_mud_hour", null);
}

pub export fn obj_on_heartbeat(obj: *cdb.obj_data, pulse: c_int) void {
    objCall(obj, "on_heartbeat", pulse);
}
