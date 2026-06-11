const std = @import("std");
const db = @import("db");
const cdb = @import("cdb");
const test_mode = @import("test_mode.zig");

fn parseRuntimeOptions(init: std.process.Init, test_options: *test_mode.Options) void {
    if (init.environ_map.get("DBAT_TEST_MODE")) |value| {
        if (std.mem.eql(u8, value, "1")) cdb.config_info.test_mode = true;
    }

    if (init.environ_map.get("DBAT_TEST_FILE")) |value| {
        if (value.len != 0) {
            test_options.file = value;
            cdb.config_info.test_mode = true;
        }
    }

    if (init.environ_map.get("DBAT_TEST_DIR")) |value| {
        if (value.len != 0) {
            test_options.dir = value;
            cdb.config_info.test_mode = true;
        }
    }

    if (init.environ_map.get("DBAT_TEST_FILTER")) |value| {
        if (value.len != 0) {
            test_options.filter = value;
            cdb.config_info.test_mode = true;
        }
    }

    if (init.environ_map.get("DBAT_TELNET_PORT")) |value| {
        cdb.port = std.fmt.parseInt(@TypeOf(cdb.port), value, 10) catch {
            std.process.fatal("invalid DBAT_TELNET_PORT: {s}", .{value});
        };
    }

    var args = std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa) catch {
        std.process.fatal("failed to initialize argument parser", .{});
    };
    defer args.deinit();

    _ = args.skip();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-t") or std.mem.eql(u8, arg, "--test")) {
            cdb.config_info.test_mode = true;
        } else if (std.mem.eql(u8, arg, "--test-file")) {
            test_options.file = args.next() orelse std.process.fatal("--test-file requires a path", .{});
            cdb.config_info.test_mode = true;
        } else if (std.mem.startsWith(u8, arg, "--test-file=")) {
            test_options.file = arg["--test-file=".len..];
            cdb.config_info.test_mode = true;
        } else if (std.mem.eql(u8, arg, "--test-dir")) {
            test_options.dir = args.next() orelse std.process.fatal("--test-dir requires a path", .{});
            cdb.config_info.test_mode = true;
        } else if (std.mem.startsWith(u8, arg, "--test-dir=")) {
            test_options.dir = arg["--test-dir=".len..];
            cdb.config_info.test_mode = true;
        } else if (std.mem.eql(u8, arg, "--test-filter")) {
            test_options.filter = args.next() orelse std.process.fatal("--test-filter requires a pattern", .{});
            cdb.config_info.test_mode = true;
        } else if (std.mem.startsWith(u8, arg, "--test-filter=")) {
            test_options.filter = arg["--test-filter=".len..];
            cdb.config_info.test_mode = true;
        } else if (std.mem.eql(u8, arg, "-C")) {
            cdb.fCopyOver = true;
        } else if (std.mem.startsWith(u8, arg, "-C")) {
            std.process.fatal("-C no longer accepts an inline descriptor argument", .{});
        } else {
            std.process.fatal("unknown argument: {s}", .{arg});
        }
    }

    if (cdb.config_info.test_mode) {
        cdb.fCopyOver = false;
    }
}

pub fn main(init: std.process.Init) u8 {
    db.init(init.gpa, init.io) catch {
        std.process.fatal("failed to initialize database", .{});
    };
    defer db.deinit();

    cdb.config_info.CONFFILE = cdb.strdup(cdb.CONFIG_FILE);

    cdb.load_config();

    cdb.port = cdb.CONFIG_DFLT_PORT();
    var test_options = test_mode.Options{};
    parseRuntimeOptions(init, &test_options);

    cdb.setup_log(cdb.CONFIG_LOGNAME(), cdb.STDERR_FILENO);

    cdb.mud_log("Using %s as data directory.", cdb.CONFIG_CONFFILE());

    cdb.mud_log("Signal trapping.");
    cdb.signal_setup();

    _ = cdb.touch(cdb.KILLSCRIPT_FILE);
    cdb.circle_srandom(@intCast(cdb.time(0)));

    cdb.mud_log("Finding player limit.");
    cdb.max_players = cdb.get_max_players();

    if (!cdb.fCopyOver and !cdb.config_info.test_mode) {
        cdb.mud_log("Opening mother connection on port %d.", cdb.port);
        const listener_fd = cdb.net_listener_open(cdb.port);
        if (listener_fd < 0) {
            std.process.fatal("failed to open listener on port {d}", .{cdb.port});
        }
    }

    cdb.event_init();

    cdb.load_race_sensei();

    cdb.boot_db();
    defer cdb.cleanup_game_world();

    cdb.load_spacemap();
    cdb.topLoad();

    _ = cdb.remove(cdb.KILLSCRIPT_FILE);
    if (cdb.fCopyOver) {
        if (!cdb.net_copyover_recover(cdb.COPYOVER_FILE)) {
            std.process.fatal("copyover recovery failed", .{});
        }
    }

    if (cdb.config_info.test_mode) {
        // Running game in test mode.
        return test_mode.run(init, test_options);
    } else {
        // Running normal gameplay loop.
        cdb.mud_log("Entering game loop.");
        cdb.game_loop();

        cdb.Crash_save_all();

        cdb.mud_log("Closing all sockets.");
        while (cdb.descriptor_list != null) {
            cdb.close_socket(cdb.descriptor_list);
        }

        cdb.net_listener_close();

        if (cdb.circle_reboot != 2) {
            _ = cdb.save_all();
        }

        cdb.mud_log("Saving current MUD time.");
        cdb.save_mud_time(&cdb.time_info);

        if (cdb.circle_reboot != 0) {
            cdb.mud_log("Rebooting.");
            return 52;
        }
    }

    cdb.mud_log("Normal termination of game.");

    return 0;
}
