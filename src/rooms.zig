const cdb = @import("cdb");
const std = @import("std");

const RoomMap = std.AutoHashMap(cdb.room_vnum, *cdb.room_data);
const RoomIdSet = std.AutoHashMap(cdb.room_vnum, void);

var allocator: std.mem.Allocator = undefined;
var room_map: RoomMap = undefined;
var subscriptions_by_tag: std.StringHashMap(RoomIdSet) = undefined;

pub fn init(init_allocator: std.mem.Allocator) void {
    allocator = init_allocator;
    room_map = RoomMap.init(allocator);
    subscriptions_by_tag = std.StringHashMap(RoomIdSet).init(allocator);
}

pub fn deinit() void {
    deinitSubscriptions();
    room_map.deinit();
    subscriptions_by_tag.deinit();
}

const RoomIterator = struct {
    iter: RoomMap.ValueIterator,
};

pub export fn room_iterator_create() ?*anyopaque {
    const iterator = allocator.create(RoomIterator) catch return null;
    iterator.* = .{ .iter = room_map.valueIterator() };
    return iterator;
}

pub export fn room_next(iterator_ptr: ?*anyopaque) ?*cdb.room_data {
    const iterator: *RoomIterator = @ptrCast(@alignCast(iterator_ptr orelse return null));
    const next_ptr = iterator.iter.next() orelse return null;
    return next_ptr.*;
}

pub export fn room_iterator_free(iterator_ptr: ?*anyopaque) void {
    const iterator = iterator_ptr orelse return;
    allocator.destroy(@as(*RoomIterator, @ptrCast(@alignCast(iterator))));
}

pub export fn room_put(vnum: cdb.room_vnum, room: ?*cdb.room_data) void {
    if (room) |ptr| {
        room_map.put(vnum, ptr) catch return;
    } else {
        room_clear_subscriptions(vnum);
        _ = room_map.remove(vnum);
    }
}

pub export fn room_delete(vnum: cdb.room_vnum) void {
    room_clear_subscriptions(vnum);
    _ = room_map.remove(vnum);
}

pub export fn room_count() usize {
    return room_map.count();
}

pub export fn room_by_id(vnum: cdb.room_vnum) ?*cdb.room_data {
    return room_map.get(vnum) orelse null;
}

pub export fn room_get(vnum: cdb.room_vnum) ?*cdb.room_data {
    return room_by_id(vnum);
}

// --- Subscription system ---

pub export fn room_subscribe_add(room: *cdb.room_data, tag: ?[*:0]const u8) c_int {
    const vnum = cdb.room_vnum_get(room);
    const name = listNameSlice(tag) orelse return -2;
    if (name.len == 0) return -2;

    var id_set = subscriptions_by_tag.getPtr(name) orelse blk: {
        const owned_name = allocator.dupe(u8, name) catch return -1;
        var new_set = RoomIdSet.init(allocator);
        subscriptions_by_tag.put(owned_name, new_set) catch {
            allocator.free(owned_name);
            new_set.deinit();
            return -1;
        };
        break :blk subscriptions_by_tag.getPtr(name).?;
    };

    id_set.put(vnum, {}) catch return -1;
    return 0;
}

pub export fn room_subscribe_remove(room: *cdb.room_data, tag: ?[*:0]const u8) void {
    const vnum = cdb.room_vnum_get(room);
    const name = listNameSlice(tag) orelse return;
    unsubscribe(vnum, name);
}

pub export fn room_unsubscribe_all(room: *cdb.room_data) void {
    room_clear_subscriptions(cdb.room_vnum_get(room));
}

pub export fn room_clear_subscriptions(vnum: cdb.room_vnum) void {
    var empty_names: [64][]const u8 = undefined;
    var empty_count: usize = 0;

    var it = subscriptions_by_tag.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.remove(vnum)) {
            if (entry.value_ptr.count() == 0 and empty_count < 64) {
                empty_names[empty_count] = entry.key_ptr.*;
                empty_count += 1;
            }
        }
    }
    for (empty_names[0..empty_count]) |name| {
        if (subscriptions_by_tag.fetchRemove(name)) |removed| {
            var val = removed.value;
            val.deinit();
            allocator.free(removed.key);
        }
    }
}

pub export fn room_subscribe_ids(tag: ?[*:0]const u8, out_count: *usize) ?[*]cdb.room_vnum {
    const name = listNameSlice(tag) orelse {
        out_count.* = 0;
        return null;
    };
    const id_set = subscriptions_by_tag.getPtr(name) orelse {
        out_count.* = 0;
        return null;
    };
    const count = id_set.count();
    const mem = std.c.malloc(count * @sizeOf(cdb.room_vnum)) orelse {
        out_count.* = 0;
        return null;
    };
    const ids: [*]cdb.room_vnum = @ptrCast(@alignCast(mem));
    var i: usize = 0;
    var it = id_set.keyIterator();
    while (it.next()) |id_ptr| {
        ids[i] = id_ptr.*;
        i += 1;
    }
    out_count.* = count;
    return ids;
}

pub export fn room_subscribe_ids_free(ptr: ?[*]cdb.room_vnum) void {
    std.c.free(@as(?*anyopaque, @ptrCast(ptr)));
}

fn unsubscribe(vnum: cdb.room_vnum, name: []const u8) void {
    removeVnumFromTag(vnum, name);
}

fn removeVnumFromTag(vnum: cdb.room_vnum, name: []const u8) void {
    const id_set = subscriptions_by_tag.getPtr(name) orelse return;
    _ = id_set.remove(vnum);

    if (id_set.count() == 0) {
        id_set.deinit();
        if (subscriptions_by_tag.fetchRemove(name)) |removed| {
            allocator.free(removed.key);
        }
    }
}

fn deinitSubscriptions() void {
    var tag_it = subscriptions_by_tag.iterator();
    while (tag_it.next()) |entry| {
        allocator.free(entry.key_ptr.*);
        entry.value_ptr.deinit();
    }
}

fn listNameSlice(list_name: ?[*:0]const u8) ?[]const u8 {
    const ptr = list_name orelse return null;
    return std.mem.span(ptr);
}
