const std = @import("std");
const cdb = @import("cdb");

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
        const wait_ms: c_int = waitUntilMs(before_wait_ns, next_tick_ns);
        if (cdb.net_wait(wait_ms) < 0) {
            std.Io.sleep(io, .fromMilliseconds(@intCast(wait_ms)), .awake) catch {};
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
                cdb.log("SYSERR: Missed %d seconds worth of pulses.", @as(c_int, @intCast(@divTrunc(late_ns, std.time.ns_per_s))));
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
