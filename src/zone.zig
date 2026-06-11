const cdb = @import("cdb");
const std = @import("std");

const ZoneMap = std.AutoHashMap(cdb.zone_vnum, *cdb.zone_data);
const IdSet = std.AutoHashMap(i64, void);
const ZoneEntityMap = std.AutoHashMap(cdb.zone_vnum, IdSet);

var allocator: std.mem.Allocator = undefined;
var zone_map: ZoneMap = undefined;
var zone_players: ZoneEntityMap = undefined;
var zone_mobs: ZoneEntityMap = undefined;
var zone_objs: ZoneEntityMap = undefined;

pub fn init(init_allocator: std.mem.Allocator) void {
    allocator = init_allocator;
    zone_map = ZoneMap.init(allocator);
    zone_players = ZoneEntityMap.init(allocator);
    zone_mobs = ZoneEntityMap.init(allocator);
    zone_objs = ZoneEntityMap.init(allocator);
}

pub fn deinit() void {
    deinitEntityMap(&zone_objs);
    deinitEntityMap(&zone_mobs);
    deinitEntityMap(&zone_players);
    zone_map.deinit();
}

fn deinitEntityMap(map: *ZoneEntityMap) void {
    var it = map.valueIterator();
    while (it.next()) |set| set.deinit();
    map.deinit();
}

fn addToZone(map: *ZoneEntityMap, vnum: cdb.zone_vnum, id: i64) void {
    const gop = map.getOrPut(vnum) catch return;
    if (!gop.found_existing) gop.value_ptr.* = IdSet.init(allocator);
    gop.value_ptr.put(id, {}) catch return;
}

fn removeFromZone(map: *ZoneEntityMap, vnum: cdb.zone_vnum, id: i64) void {
    const set = map.getPtr(vnum) orelse return;
    _ = set.remove(id);
    if (set.count() == 0) {
        set.deinit();
        _ = map.remove(vnum);
    }
}

fn countInZone(map: *ZoneEntityMap, vnum: cdb.zone_vnum) usize {
    return if (map.getPtr(vnum)) |s| s.count() else 0;
}

fn idsForZone(map: *ZoneEntityMap, vnum: cdb.zone_vnum, out_count: *usize) ?[*]i64 {
    const set = map.getPtr(vnum) orelse { out_count.* = 0; return null; };
    const count = set.count();
    if (count == 0) { out_count.* = 0; return null; }
    const mem = std.c.malloc(count * @sizeOf(i64)) orelse { out_count.* = 0; return null; };
    const ids: [*]i64 = @ptrCast(@alignCast(mem));
    var i: usize = 0;
    var it = set.keyIterator();
    while (it.next()) |id_ptr| { ids[i] = id_ptr.*; i += 1; }
    out_count.* = count;
    return ids;
}

// --- Zone map ---

const ZoneIterator = struct {
    iter: ZoneMap.ValueIterator,
};

pub export fn zone_iterator_create() ?*anyopaque {
    const iterator = allocator.create(ZoneIterator) catch return null;
    iterator.* = .{ .iter = zone_map.valueIterator() };
    return iterator;
}

pub export fn zone_next(iterator_ptr: ?*anyopaque) ?*cdb.zone_data {
    const iterator: *ZoneIterator = @ptrCast(@alignCast(iterator_ptr orelse return null));
    const next_ptr = iterator.iter.next() orelse return null;
    return next_ptr.*;
}

pub export fn zone_iterator_free(iterator_ptr: ?*anyopaque) void {
    const iterator = iterator_ptr orelse return;
    allocator.destroy(@as(*ZoneIterator, @ptrCast(@alignCast(iterator))));
}

pub export fn zone_put(vnum: cdb.zone_vnum, zone: ?*cdb.zone_data) void {
    if (zone) |ptr| {
        zone_map.put(vnum, ptr) catch return;
    } else {
        _ = zone_map.remove(vnum);
    }
}

pub export fn zone_delete(vnum: cdb.zone_vnum) void {
    _ = zone_map.remove(vnum);
}

pub export fn zone_count() usize {
    return zone_map.count();
}

pub export fn zone_get(vnum: cdb.zone_vnum) ?*cdb.zone_data {
    return zone_map.get(vnum) orelse null;
}

// --- Players ---

pub export fn zone_player_add(vnum: cdb.zone_vnum, id: i64) void {
    addToZone(&zone_players, vnum, id);
}

pub export fn zone_player_remove(vnum: cdb.zone_vnum, id: i64) void {
    removeFromZone(&zone_players, vnum, id);
}

pub export fn zone_player_count(vnum: cdb.zone_vnum) usize {
    return countInZone(&zone_players, vnum);
}

pub export fn zone_player_count_get(vnum: cdb.zone_vnum) c_int {
    return @intCast(countInZone(&zone_players, vnum));
}

pub export fn zone_player_ids(vnum: cdb.zone_vnum, out_count: *usize) ?[*]i64 {
    return idsForZone(&zone_players, vnum, out_count);
}

pub export fn zone_player_ids_free(ptr: ?[*]i64) void {
    std.c.free(@as(?*anyopaque, @ptrCast(ptr)));
}

// --- Mobs ---

pub export fn zone_mob_add(vnum: cdb.zone_vnum, id: i64) void {
    addToZone(&zone_mobs, vnum, id);
}

pub export fn zone_mob_remove(vnum: cdb.zone_vnum, id: i64) void {
    removeFromZone(&zone_mobs, vnum, id);
}

pub export fn zone_mob_count(vnum: cdb.zone_vnum) usize {
    return countInZone(&zone_mobs, vnum);
}

pub export fn zone_mob_count_get(vnum: cdb.zone_vnum) c_int {
    return @intCast(countInZone(&zone_mobs, vnum));
}

pub export fn zone_mob_ids(vnum: cdb.zone_vnum, out_count: *usize) ?[*]i64 {
    return idsForZone(&zone_mobs, vnum, out_count);
}

pub export fn zone_mob_ids_free(ptr: ?[*]i64) void {
    std.c.free(@as(?*anyopaque, @ptrCast(ptr)));
}

// --- Objects ---

pub export fn zone_obj_add(vnum: cdb.zone_vnum, id: i64) void {
    addToZone(&zone_objs, vnum, id);
}

pub export fn zone_obj_remove(vnum: cdb.zone_vnum, id: i64) void {
    removeFromZone(&zone_objs, vnum, id);
}

pub export fn zone_obj_count(vnum: cdb.zone_vnum) usize {
    return countInZone(&zone_objs, vnum);
}

pub export fn zone_obj_count_get(vnum: cdb.zone_vnum) c_int {
    return @intCast(countInZone(&zone_objs, vnum));
}

pub export fn zone_obj_ids(vnum: cdb.zone_vnum, out_count: *usize) ?[*]i64 {
    return idsForZone(&zone_objs, vnum, out_count);
}

pub export fn zone_obj_ids_free(ptr: ?[*]i64) void {
    std.c.free(@as(?*anyopaque, @ptrCast(ptr)));
}
