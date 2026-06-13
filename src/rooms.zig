const cdb = @import("cdb");
const std = @import("std");

const RoomMap = std.AutoHashMap(cdb.room_vnum, *cdb.room_data);
const RoomIdSet = std.AutoHashMap(cdb.room_vnum, void);
const IdList = std.ArrayListUnmanaged(i64);

var allocator: std.mem.Allocator = undefined;
var room_map: RoomMap = undefined;
var subscriptions_by_tag: std.StringHashMap(RoomIdSet) = undefined;
var room_people_map: std.AutoHashMap(cdb.room_vnum, IdList) = undefined;
var room_objects_map: std.AutoHashMap(cdb.room_vnum, IdList) = undefined;

pub fn init(init_allocator: std.mem.Allocator) void {
    allocator = init_allocator;
    room_map = RoomMap.init(allocator);
    subscriptions_by_tag = std.StringHashMap(RoomIdSet).init(allocator);
    room_people_map = std.AutoHashMap(cdb.room_vnum, IdList).init(allocator);
    room_objects_map = std.AutoHashMap(cdb.room_vnum, IdList).init(allocator);
}

pub fn deinit() void {
    deinitSubscriptions();
    room_map.deinit();
    subscriptions_by_tag.deinit();
    {
        var it = room_people_map.valueIterator();
        while (it.next()) |list| list.deinit(allocator);
        room_people_map.deinit();
    }
    {
        var it = room_objects_map.valueIterator();
        while (it.next()) |list| list.deinit(allocator);
        room_objects_map.deinit();
    }
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
        cleanupRoomContainment(vnum);
        _ = room_map.remove(vnum);
    }
}

pub export fn room_delete(vnum: cdb.room_vnum) void {
    room_clear_subscriptions(vnum);
    cleanupRoomContainment(vnum);
    _ = room_map.remove(vnum);
}

fn cleanupRoomContainment(vnum: cdb.room_vnum) void {
    if (room_people_map.fetchRemove(vnum)) |kv| {
        var list = kv.value;
        list.deinit(allocator);
    }
    if (room_objects_map.fetchRemove(vnum)) |kv| {
        var list = kv.value;
        list.deinit(allocator);
    }
}

// --- Room containment ID tracking ---

pub export fn room_person_add(room: *cdb.room_data, ch: *cdb.char_data) void {
    const vnum = cdb.room_vnum_get(room);
    const id = cdb.char_id_get(ch);
    const entry = room_people_map.getOrPut(vnum) catch return;
    if (!entry.found_existing) entry.value_ptr.* = IdList.empty;
    entry.value_ptr.append(allocator, id) catch {};
}

pub export fn room_person_remove(room: *cdb.room_data, ch: *cdb.char_data) void {
    const vnum = cdb.room_vnum_get(room);
    const id = cdb.char_id_get(ch);
    const list = room_people_map.getPtr(vnum) orelse return;
    for (list.items, 0..) |item, i| {
        if (item == id) {
            _ = list.swapRemove(i);
            return;
        }
    }
}

pub export fn room_person_ids(room: *cdb.room_data, out_count: *usize) ?[*]i64 {
    const vnum = cdb.room_vnum_get(room);
    const list = room_people_map.getPtr(vnum) orelse {
        out_count.* = 0;
        return null;
    };
    const count = list.items.len;
    if (count == 0) {
        out_count.* = 0;
        return null;
    }
    const mem = std.c.malloc(count * @sizeOf(i64)) orelse {
        out_count.* = 0;
        return null;
    };
    const ids: [*]i64 = @ptrCast(@alignCast(mem));
    @memcpy(ids[0..count], list.items);
    out_count.* = count;
    return ids;
}

pub export fn room_person_ids_free(ptr: ?[*]i64) void {
    std.c.free(@as(?*anyopaque, @ptrCast(ptr)));
}

pub export fn room_object_add(room: *cdb.room_data, obj: *cdb.obj_data) void {
    const vnum = cdb.room_vnum_get(room);
    const id = cdb.obj_id_get(obj);
    const entry = room_objects_map.getOrPut(vnum) catch return;
    if (!entry.found_existing) entry.value_ptr.* = IdList.empty;
    entry.value_ptr.append(allocator, id) catch {};
}

pub export fn room_object_remove(room: *cdb.room_data, obj: *cdb.obj_data) void {
    const vnum = cdb.room_vnum_get(room);
    const id = cdb.obj_id_get(obj);
    const list = room_objects_map.getPtr(vnum) orelse return;
    for (list.items, 0..) |item, i| {
        if (item == id) {
            _ = list.swapRemove(i);
            return;
        }
    }
}

pub export fn room_object_ids(room: *cdb.room_data, out_count: *usize) ?[*]i64 {
    const vnum = cdb.room_vnum_get(room);
    const list = room_objects_map.getPtr(vnum) orelse {
        out_count.* = 0;
        return null;
    };
    const count = list.items.len;
    if (count == 0) {
        out_count.* = 0;
        return null;
    }
    const mem = std.c.malloc(count * @sizeOf(i64)) orelse {
        out_count.* = 0;
        return null;
    };
    const ids: [*]i64 = @ptrCast(@alignCast(mem));
    @memcpy(ids[0..count], list.items);
    out_count.* = count;
    return ids;
}

pub export fn room_object_ids_free(ptr: ?[*]i64) void {
    std.c.free(@as(?*anyopaque, @ptrCast(ptr)));
}

pub export fn room_person_first(room: *cdb.room_data) ?*cdb.char_data {
    const vnum = cdb.room_vnum_get(room);
    const list = room_people_map.getPtr(vnum) orelse return null;
    if (list.items.len == 0) return null;
    return cdb.char_by_id(list.items[0]);
}

pub export fn room_object_first(room: *cdb.room_data) ?*cdb.obj_data {
    const vnum = cdb.room_vnum_get(room);
    const list = room_objects_map.getPtr(vnum) orelse return null;
    if (list.items.len == 0) return null;
    return cdb.obj_by_id(list.items[0]);
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
