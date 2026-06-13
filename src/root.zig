const std = @import("std");

pub const cdb = @import("cdb");
pub const characters = @import("character.zig");
pub const characters_api = @import("character_api.zig");
pub const modifiers_api = @import("modifiers_api.zig");
pub const objects = @import("object.zig");
pub const objects_api = @import("object_api.zig");
pub const rooms = @import("rooms.zig");
pub const rooms_api = @import("room_api.zig");
pub const exits_api = @import("exits_api.zig");
pub const exits_json = @import("exits_json.zig");
pub const shops_api = @import("shop_api.zig");
pub const shops = @import("shop.zig");
pub const guilds_api = @import("guild_api.zig");
pub const guilds = @import("guild.zig");
pub const zones = @import("zone.zig");
pub const zones_api = @import("zone_api.zig");
pub const lua_api = @import("lua_api.zig");
pub const intern = @import("intern.zig");
pub const json_api = @import("json_api.zig");
pub const flags_json = @import("flags_json.zig");
pub const extradesc_json = @import("extradesc_json.zig");
pub const affected_json = @import("affected_json.zig");
pub const rooms_json = @import("room_json.zig");
pub const objects_json = @import("object_json.zig");
pub const characters_json = @import("character_json.zig");
pub const zones_json = @import("zone_json.zig");
pub const shops_json = @import("shop_json.zig");
pub const guilds_json = @import("guild_json.zig");
pub const players_json = @import("player_files_json.zig");
pub const assembly_json = @import("assembly_json.zig");
pub const dgscripts_json = @import("dgscript_json.zig");
pub const dgscripts = @import("dgscript.zig");
pub const net = @import("net.zig");
pub const game = @import("game.zig");
pub const event_queue = @import("event_queue.zig");
pub const auth = @import("auth.zig");

// This stupid comptime and its function ensures that the C API functions aren't optimized out because Zig doesn't call them directly. They are called from C, so we have to force them to be included in the final binary.
comptime {
    forceApiExports(characters_api);
    std.testing.refAllDecls(modifiers_api);
    forceApiExports(objects_api);
    forceApiExports(rooms);
    forceApiExports(rooms_api);
    forceApiExports(exits_api);
    forceApiExports(shops_api);
    forceApiExports(shops);
    forceApiExports(guilds_api);
    forceApiExports(guilds);
    forceApiExports(zones);
    forceApiExports(zones_api);
    forceApiExports(lua_api);
    forceApiExports(intern);
    forceApiExports(json_api);
    forceApiExports(dgscripts);
    forceApiExports(net);
    forceApiExports(game);
    forceApiExports(event_queue);
    forceApiExports(auth);
    std.testing.refAllDecls(flags_json);
    std.testing.refAllDecls(extradesc_json);
    std.testing.refAllDecls(dgscripts_json);
    std.testing.refAllDecls(exits_json);
    std.testing.refAllDecls(rooms_json);
    std.testing.refAllDecls(objects_json);
    std.testing.refAllDecls(zones_json);
    std.testing.refAllDecls(characters_json);
    std.testing.refAllDecls(shops_json);
    std.testing.refAllDecls(guilds_json);
    std.testing.refAllDecls(players_json);
}

fn forceApiExports(comptime module: type) void {
    inline for (std.meta.declarations(module)) |decl| {
        _ = @field(module, decl.name);
    }
}

pub fn init(allocator: std.mem.Allocator, io: std.Io) !void {
    characters.init(allocator);
    objects.init(allocator);
    rooms.init(allocator);
    shops.init(allocator);
    guilds.init(allocator);
    zones.init(allocator);
    dgscripts.init(allocator);
    intern.init(allocator);
    net.init(allocator, io);
    game.init(io);
    event_queue.init(allocator, io);
    auth.init(allocator, io);
    json_api.init(io);
    players_json.init(io);
    try lua_api.init(allocator, io);

    try lua_api.load_lua();

    cdb.event_queue_register_heartbeat_events();
}

pub fn deinit() void {
    lua_api.deinit();
    intern.deinit();
    event_queue.deinit();
    game.deinit();
    net.deinit();
    dgscripts.deinit();
    zones.deinit();
    guilds.deinit();
    shops.deinit();
    rooms.deinit();
    objects.deinit();
    characters.deinit();
}
