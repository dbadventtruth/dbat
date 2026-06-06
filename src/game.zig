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

pub export fn game_loop(mother_desc: cdb.socklen_t) void {
    if (!has_io) {
        cdb.game_loop_legacy(mother_desc);
        return;
    }

    var last = std.Io.Timestamp.now(io, .awake);
    while (cdb.circle_shutdown == 0) {
        if (cdb.descriptor_list == null) {
            cdb.game_legacy_network_wait(mother_desc);
            last = std.Io.Timestamp.now(io, .awake);
        }

        const before_sleep = std.Io.Timestamp.now(io, .awake);
        const elapsed_before_sleep = last.durationTo(before_sleep);
        if (elapsed_before_sleep.nanoseconds < tick.nanoseconds) {
            std.Io.sleep(io, .fromNanoseconds(tick.nanoseconds - elapsed_before_sleep.nanoseconds), .awake) catch {};
        }

        const now = std.Io.Timestamp.now(io, .awake);
        const elapsed = last.durationTo(now);
        last = now;

        if (!cdb.game_legacy_network_pump(mother_desc)) return;

        cdb.extract_pending_chars();

        if (active_players > 0) {
            var pulses_due: usize = @intCast(@max(@as(i96, 1), @divTrunc(elapsed.nanoseconds, tick.nanoseconds)));
            if (pulses_due > max_catchup_pulses) {
                cdb.log("SYSERR: Missed %d seconds worth of pulses.", @as(c_int, @intCast(pulses_due / 10)));
                pulses_due = max_catchup_pulses;
            }

            while (pulses_due > 0) : (pulses_due -= 1) {
                cdb.pulse += 1;
                heartbeat(@intCast(cdb.pulse));
            }
        }

        cdb.extract_pending_chars();

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
