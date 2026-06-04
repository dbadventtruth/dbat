const std = @import("std");
const db = @import("db");
const cdb = @import("cdb");

pub fn main(init: std.process.Init) u8 {
    db.init(init.gpa, init.io) catch {
        std.process.fatal("failed to initialize database", .{});
    };
    defer db.deinit();

    cdb.config_info.CONFFILE = cdb.strdup(cdb.CONFIG_FILE);

    cdb.load_config();

    cdb.port = cdb.CONFIG_DFLT_PORT();

    cdb.setup_log(cdb.CONFIG_LOGNAME(), cdb.STDERR_FILENO);

    cdb.log("Using %s as data directory.", cdb.CONFIG_CONFFILE());

    cdb.log("Signal trapping.");
    cdb.signal_setup();

    _ = cdb.touch(cdb.KILLSCRIPT_FILE);
    cdb.circle_srandom(@intCast(cdb.time(0)));

    cdb.log("Finding player limit.");
    cdb.max_players = cdb.get_max_players();

    if (!cdb.fCopyOver) {
    cdb.log("Opening mother connection on port %d.", cdb.port);
        cdb.mother_desc = cdb.init_socket(cdb.port);
    }

    cdb.event_init();

    cdb.load_race_sensei();

    cdb.boot_db();
    defer cdb.cleanup_game_world();

    cdb.load_spacemap();
    cdb.topLoad();

    _ = cdb.remove(cdb.KILLSCRIPT_FILE);
    if (cdb.fCopyOver) {
        cdb.copyover_recover();
    }

    cdb.log("Entering game loop.");
    cdb.game_loop(cdb.mother_desc);

    cdb.Crash_save_all();

    cdb.log("Closing all sockets.");
    while (cdb.descriptor_list != null) {
        cdb.close_socket(cdb.descriptor_list);
    }

    _ = cdb.close(@intCast(cdb.mother_desc));

    if (cdb.circle_reboot != 2) {
        _ = cdb.save_all();
    }

    cdb.log("Saving current MUD time.");
    cdb.save_mud_time(&cdb.time_info);

    if (cdb.circle_reboot != 0) {
        cdb.log("Rebooting.");
        return 52;
    }

    cdb.log("Normal termination of game.");

    return 0;
}
