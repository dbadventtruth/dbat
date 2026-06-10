const cdb = @import("cdb");
const std = @import("std");

const ZoneMap = std.AutoHashMap(cdb.zone_vnum, *cdb.zone_data);
const PlayerCountMap = std.AutoHashMap(cdb.zone_vnum, i32);

var allocator: std.mem.Allocator = undefined;
var zone_map: ZoneMap = undefined;
var zone_players: PlayerCountMap = undefined;

pub fn init(init_allocator: std.mem.Allocator) void {
    allocator = init_allocator;
    zone_map = ZoneMap.init(allocator);
    zone_players = PlayerCountMap.init(allocator);
}

pub fn deinit() void {
    zone_map.deinit();
    zone_players.deinit();
}

pub export fn zone_player_count_inc(vnum: cdb.zone_vnum) void {
    const entry = zone_players.getOrPutValue(vnum, 0) catch return;
    entry.value_ptr.* += 1;
}

pub export fn zone_player_count_dec(vnum: cdb.zone_vnum) void {
    if (zone_players.getPtr(vnum)) |ptr| {
        if (ptr.* > 0) ptr.* -= 1;
    }
}

pub export fn zone_player_count_get(vnum: cdb.zone_vnum) c_int {
    return zone_players.get(vnum) orelse 0;
}

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
