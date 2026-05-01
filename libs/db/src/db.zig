const std = @import("std");
const deps = @import("deps.zig");
const cdb = deps.cdb;

pub const GameDB = struct {
    real_room_map: std.AutoHashMap(cdb.room_vnum, cdb.room_rnum),
    real_mobile_map: std.AutoHashMap(cdb.mob_vnum, cdb.mob_rnum),
    real_object_map: std.AutoHashMap(cdb.obj_vnum, cdb.obj_rnum),
    real_zone_map: std.AutoHashMap(cdb.zone_vnum, cdb.zone_rnum),
    real_shop_map: std.AutoHashMap(cdb.shop_vnum, cdb.shop_rnum),
    real_guild_map: std.AutoHashMap(cdb.guild_vnum, cdb.guild_rnum),

    pub fn init(allocator: std.mem.Allocator) !GameDB {
        return GameDB{
            .real_room_map = std.AutoHashMap(cdb.room_vnum, cdb.room_rnum).init(allocator),
            .real_mobile_map = std.AutoHashMap(cdb.mob_vnum, cdb.mob_rnum).init(allocator),
            .real_object_map = std.AutoHashMap(cdb.obj_vnum, cdb.obj_rnum).init(allocator),
            .real_zone_map = std.AutoHashMap(cdb.zone_vnum, cdb.zone_rnum).init(allocator),
            .real_shop_map = std.AutoHashMap(cdb.shop_vnum, cdb.shop_rnum).init(allocator),
            .real_guild_map = std.AutoHashMap(cdb.guild_vnum, cdb.guild_rnum).init(allocator),
        };
    }

    pub fn deinit(self: *GameDB) void {
        self.real_room_map.deinit();
        self.real_mobile_map.deinit();
        self.real_object_map.deinit();
        self.real_zone_map.deinit();
        self.real_shop_map.deinit();
        self.real_guild_map.deinit();
    }
};

var global_db: ?GameDB = null;

pub fn init(allocator: std.mem.Allocator) !void {
    if (global_db != null) return error.AlreadyInitialized;
    global_db = try GameDB.init(allocator);
}

pub fn deinit() void {
    if (global_db) |*dbase| {
        dbase.deinit();
        global_db = null;
    }
}

pub export fn init_zig() void {
    const allocator = std.heap.page_allocator;
    // we have to call init() but can't return anything; jjust panic if it fails
    init(allocator) catch @panic("failed to initialize GameDB");
    return;
}

pub export fn deinit_zig() void {
    deinit();
}

fn db() *GameDB {
    return &(global_db orelse @panic("GameDB not initialized"));
}

// Exported functions for the database below.

// rooms!
pub export fn real_room(vnum: cdb.room_vnum) cdb.room_rnum {
    const game_db = db();
    return game_db.real_room_map.get(vnum) orelse -1;
}

pub export fn room_game_register(vnum: cdb.room_vnum, rnum: cdb.room_rnum) void {
    db().real_room_map.put(vnum, rnum) catch @panic("failed to register room");
}
pub export fn room_game_deregister(vnum: cdb.room_vnum) void {
    _ = db().real_room_map.remove(vnum);
}

pub export fn room_by_id(vnum: cdb.room_vnum) ?*cdb.room_data {
    const rnum = real_room(vnum);
    if (rnum == -1) return null;
    return &cdb.world[@intCast(rnum)];
}

// zones!
pub export fn real_zone(vnum: cdb.zone_vnum) cdb.zone_rnum {
    const game_db = db();
    return game_db.real_zone_map.get(vnum) orelse -1;
}

pub export fn zone_game_register(vnum: cdb.zone_vnum, rnum: cdb.zone_rnum) void {
    db().real_zone_map.put(vnum, rnum) catch @panic("failed to register zone");
}
pub export fn zone_game_deregister(vnum: cdb.zone_vnum) void {
    _ = db().real_zone_map.remove(vnum);
}
pub export fn zone_by_id(vnum: cdb.zone_vnum) ?*cdb.zone_data {
    const rnum = real_zone(vnum);
    if (rnum == -1) return null;
    return &cdb.zone_table[@intCast(rnum)];
}

// object prototypes!
pub export fn real_object(vnum: cdb.obj_vnum) cdb.obj_rnum {
    const game_db = db();
    return game_db.real_object_map.get(vnum) orelse -1;
}

pub export fn object_prototype_register(vnum: cdb.obj_vnum, rnum: cdb.obj_rnum) void {
    db().real_object_map.put(vnum, rnum) catch @panic("failed to register object prototype");
}
pub export fn object_prototype_deregister(vnum: cdb.obj_vnum) void {
    _ = db().real_object_map.remove(vnum);
}

pub export fn object_prototype_by_id(vnum: cdb.obj_vnum) ?*cdb.obj_data {
    const rnum = real_object(vnum);
    if (rnum == -1) return null;
    return &cdb.obj_proto[@intCast(rnum)];
}

// mobile prototypes!
pub export fn real_mobile(vnum: cdb.mob_vnum) cdb.mob_rnum {
    const game_db = db();
    return game_db.real_mobile_map.get(vnum) orelse -1;
}

pub export fn mobile_prototype_register(vnum: cdb.mob_vnum, rnum: cdb.mob_rnum) void {
    db().real_mobile_map.put(vnum, rnum) catch @panic("failed to register mobile prototype");
}
pub export fn mobile_prototype_deregister(vnum: cdb.mob_vnum) void {
    _ = db().real_mobile_map.remove(vnum);
}
pub export fn mobile_prototype_by_id(vnum: cdb.mob_vnum) ?*cdb.char_data {
    const rnum = real_mobile(vnum);
    if (rnum == -1) return null;
    return &cdb.mob_proto[@intCast(rnum)];
}
