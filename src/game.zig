const std = @import("std");
const cdb = @import("cdb");
const lua_api = @import("lua_api.zig");
const http_server = @import("http_server.zig");
const characters_lua = @import("character_lua.zig");
const rooms_lua = @import("room_lua.zig");
const objects_lua = @import("object_lua.zig");
const zones_lua = @import("zone_lua.zig");
const event_queue = @import("event_queue.zig");


var io: std.Io = undefined;
var has_io = false;
var active_players: usize = 0;

const tick = std.Io.Duration.fromMilliseconds(100);

pub fn init(runtime_io: std.Io) void {
    io = runtime_io;
    active_players = 0;
    has_io = true;
    event_queue.setEntityUpdateFn(fireEntityUpdate);
}

fn fireEntityUpdate(kind: []const u8, ctx_type: c_int, entity_id: i64) void {
    const lua = lua_api.state();
    const top = lua.getTop();
    defer lua.setTop(top);

    pushEntityByCtx(lua, ctx_type, entity_id);
    if (lua.typeOf(-1) != .userdata) return;

    if (lua.getField(-1, "on_event") != .function) {
        lua.pop(1);
        return;
    }

    pushEntityByCtx(lua, ctx_type, entity_id);
    _ = lua.pushString(kind);

    lua.protectedCall(.{ .args = 2, .results = 0 }) catch |err| {
        const msg = lua.toString(-1) catch @errorName(err);
        std.log.err("on_event '{s}' failed: {s}", .{ kind, msg });
        lua.pop(1);
    };
}

fn pushEntityByCtx(lua: anytype, ctx_type: c_int, entity_id: i64) void {
    switch (ctx_type) {
        event_queue.CTX_CHAR_ID => characters_lua.pushCharacter(lua, entity_id),
        event_queue.CTX_ROOM_ID => rooms_lua.pushRoom(lua, @intCast(entity_id)),
        event_queue.CTX_OBJ_ID  => objects_lua.pushObject(lua, entity_id),
        event_queue.CTX_ZONE_ID => zones_lua.pushZone(lua, @intCast(entity_id)),
        else => lua.pushNil(),
    }
}

pub fn deinit() void {
    active_players = 0;
    has_io = false;
}

fn logSlow(comptime phase: [:0]const u8, start_ns: i96) void {
    const elapsed_ms: i64 = @intCast(@min(@divTrunc(nowNs() - start_ns, std.time.ns_per_ms), 999_999));
    if (elapsed_ms >= 200)
        cdb.mud_log("PERF: game_loop/" ++ phase ++ " took %dms", @as(c_int, @intCast(elapsed_ms)));
}

pub export fn game_loop() void {
    var next_tick_ns = nowNs() + tick.nanoseconds;
    while (cdb.circle_shutdown == 0) {
        const before_wait_ns = nowNs();
        const now_ms = nowMs();

        // Drain any events that are due before waiting for I/O.
        const t_eq = nowNs();
        event_queue.process(now_ms);
        logSlow("event_queue", t_eq);

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
        http_server.acceptPending();
        _ = cdb.net_read_all_pending();
        http_server.readPending();
        const t_cmd = nowNs();
        cdb.game_legacy_process_commands();
        logSlow("process_commands", t_cmd);
        http_server.processRequests();

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
        }

        cdb.extract_pending_chars();

        cdb.game_legacy_send_outputs();
        _ = cdb.net_flush_all_outputs();
        http_server.flushOutputs();
        http_server.closeCompleted();
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

pub export fn game_active_player_enter() void {
    active_players += 1;
}

pub export fn game_active_player_leave() void {
    if (active_players > 0) active_players -= 1;
}

pub export fn game_active_player_count() c_int {
    return @intCast(@min(active_players, @as(usize, @intCast(std.math.maxInt(c_int)))));
}

