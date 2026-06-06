const std = @import("std");
const cdb = @import("cdb");

var io: std.Io = undefined;
var has_io = false;
var active_players: usize = 0;

const tick = std.Io.Duration.fromMilliseconds(100);
const max_catchup_pulses = 30 * 10;

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
    var last = std.Io.Timestamp.now(io, .awake);
    while (cdb.circle_shutdown == 0) {
        const before_wait = std.Io.Timestamp.now(io, .awake);
        const elapsed_before_wait = last.durationTo(before_wait);
        const wait_ms: c_int = if (elapsed_before_wait.nanoseconds >= tick.nanoseconds)
            0
        else
            @intCast(@max(@as(i96, 1), @divTrunc(tick.nanoseconds - elapsed_before_wait.nanoseconds, std.time.ns_per_ms)));
        if (cdb.net_wait(wait_ms) < 0) {
            std.Io.sleep(io, .fromMilliseconds(@intCast(wait_ms)), .awake) catch {};
        }

        const now = std.Io.Timestamp.now(io, .awake);
        const elapsed = last.durationTo(now);

        _ = cdb.net_accept_all_pending();
        _ = cdb.net_read_all_pending();
        cdb.game_legacy_process_commands();

        cdb.extract_pending_chars();

        if (active_players > 0 and elapsed.nanoseconds >= tick.nanoseconds) {
            last = now;
            var pulses_due: usize = @intCast(@divTrunc(elapsed.nanoseconds, tick.nanoseconds));
            if (pulses_due > max_catchup_pulses) {
                cdb.log("SYSERR: Missed %d seconds worth of pulses.", @as(c_int, @intCast(pulses_due / 10)));
                pulses_due = max_catchup_pulses;
            }

            while (pulses_due > 0) : (pulses_due -= 1) {
                cdb.pulse += 1;
                heartbeat(@intCast(cdb.pulse));
            }
        } else if (active_players == 0) {
            last = now;
        }

        cdb.extract_pending_chars();

        cdb.game_legacy_send_outputs();
        _ = cdb.net_flush_all_outputs();
        cdb.game_legacy_close_pending();

        cdb.game_legacy_post_tick();
    }
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
