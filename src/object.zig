const cdb = @import("cdb");
const std = @import("std");
const event_queue = @import("event_queue.zig");

const IdSet = std.AutoHashMap(i64, void);
const IdList = std.ArrayListUnmanaged(i64);
const ObjCallback = *const fn (*cdb.obj_data) callconv(.c) void;
const ObjProtoEntry = struct {
    proto: ?*cdb.obj_proto_data = null,
    special: cdb.SpecialFunc = null,
    count: usize = 0,
};
const ObjProtoMap = std.AutoHashMap(cdb.obj_vnum, ObjProtoEntry);

var allocator: std.mem.Allocator = undefined;
var objs_by_id: std.AutoHashMap(i64, *cdb.obj_data) = undefined;
var subscriptions_by_list: std.StringHashMap(IdSet) = undefined;
var obj_proto_map: ObjProtoMap = undefined;
var obj_contents_map: std.AutoHashMap(i64, IdList) = undefined;

pub fn init(init_allocator: std.mem.Allocator) void {
    allocator = init_allocator;
    objs_by_id = std.AutoHashMap(i64, *cdb.obj_data).init(allocator);
    subscriptions_by_list = std.StringHashMap(IdSet).init(allocator);
    obj_proto_map = ObjProtoMap.init(allocator);
    obj_contents_map = std.AutoHashMap(i64, IdList).init(allocator);
}

pub fn deinit() void {
    deinitSubscriptions();
    objs_by_id.deinit();
    obj_proto_map.deinit();
    {
        var it = obj_contents_map.valueIterator();
        while (it.next()) |list| list.deinit(allocator);
        obj_contents_map.deinit();
    }
}

pub export fn obj_by_id(id: i64) ?*cdb.obj_data {
    return objs_by_id.get(id) orelse null;
}

pub export fn obj_register_id(id: i64, obj: ?*cdb.obj_data) c_int {
    const ptr = obj orelse {
        obj_unregister_id(id);
        return 0;
    };

    objs_by_id.put(id, ptr) catch return -1;
    return 0;
}

pub export fn obj_unregister_id(id: i64) void {
    obj_clear_subscriptions(id);
    _ = event_queue.cancelOwner(event_queue.OWNER_OBJ, id, null);
    if (obj_contents_map.fetchRemove(id)) |kv| {
        var list = kv.value;
        list.deinit(allocator);
    }
    _ = objs_by_id.remove(id);
}

pub export fn obj_subscribe(id: i64, list_name: ?[*:0]const u8) c_int {
    const name = listNameSlice(list_name) orelse return -2;
    if (name.len == 0) return -2;

    var id_set = subscriptions_by_list.getPtr(name) orelse blk: {
        const owned_name = allocator.dupe(u8, name) catch return -1;
        var new_set = IdSet.init(allocator);
        subscriptions_by_list.put(owned_name, new_set) catch {
            allocator.free(owned_name);
            new_set.deinit();
            return -1;
        };
        break :blk subscriptions_by_list.getPtr(name).?;
    };

    id_set.put(id, {}) catch return -1;
    return 0;
}

pub export fn obj_unsubscribe(id: i64, list_name: ?[*:0]const u8) void {
    const name = listNameSlice(list_name) orelse return;
    unsubscribe(id, name);
}

pub export fn obj_clear_subscriptions(id: i64) void {
    var empty_names: [64][]const u8 = undefined;
    var empty_count: usize = 0;

    var it = subscriptions_by_list.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.remove(id)) {
            if (entry.value_ptr.count() == 0 and empty_count < 64) {
                empty_names[empty_count] = entry.key_ptr.*;
                empty_count += 1;
            }
        }
    }
    for (empty_names[0..empty_count]) |name| {
        if (subscriptions_by_list.fetchRemove(name)) |removed| {
            var val = removed.value;
            val.deinit();
            allocator.free(removed.key);
        }
    }
}

pub export fn obj_for_each(list_name: ?[*:0]const u8, callback: ?ObjCallback) void {
    const name = listNameSlice(list_name) orelse return;
    const cb = callback orelse return;
    const id_set = subscriptions_by_list.getPtr(name) orelse return;

    var it = id_set.keyIterator();
    while (it.next()) |id_ptr| {
        if (obj_by_id(id_ptr.*)) |obj| {
            cb(obj);
        }
    }
}

pub export fn obj_subscribe_add(obj: *cdb.obj_data, tag: ?[*:0]const u8) c_int {
    return obj_subscribe(cdb.obj_id_get(obj), tag);
}

pub export fn obj_subscribe_remove(obj: *cdb.obj_data, tag: ?[*:0]const u8) void {
    obj_unsubscribe(cdb.obj_id_get(obj), tag);
}

pub export fn obj_unsubscribe_all(obj: *cdb.obj_data) void {
    obj_clear_subscriptions(cdb.obj_id_get(obj));
}

pub export fn obj_subscribe_ids(tag: ?[*:0]const u8, out_count: *usize) ?[*]i64 {
    const name = listNameSlice(tag) orelse {
        out_count.* = 0;
        return null;
    };
    const id_set = subscriptions_by_list.getPtr(name) orelse {
        out_count.* = 0;
        return null;
    };
    const count = id_set.count();
    const mem = std.c.malloc(count * @sizeOf(i64)) orelse {
        out_count.* = 0;
        return null;
    };
    const ids: [*]i64 = @ptrCast(@alignCast(mem));
    var i: usize = 0;
    var it = id_set.keyIterator();
    while (it.next()) |id_ptr| {
        ids[i] = id_ptr.*;
        i += 1;
    }
    out_count.* = count;
    return ids;
}

pub export fn obj_subscribe_ids_free(ptr: ?[*]i64) void {
    std.c.free(@as(?*anyopaque, @ptrCast(ptr)));
}

// Snapshot of every live object id. Free with obj_subscribe_ids_free.
pub export fn obj_all_ids(out_count: *usize) ?[*]i64 {
    const count = objs_by_id.count();
    if (count == 0) {
        out_count.* = 0;
        return null;
    }
    const mem = std.c.malloc(count * @sizeOf(i64)) orelse {
        out_count.* = 0;
        return null;
    };
    const ids: [*]i64 = @ptrCast(@alignCast(mem));
    var i: usize = 0;
    var it = objs_by_id.keyIterator();
    while (it.next()) |id_ptr| {
        ids[i] = id_ptr.*;
        i += 1;
    }
    out_count.* = count;
    return ids;
}

// Same snapshot sorted newest-first (descending id). Ids are assigned
// monotonically at creation, so this reproduces the old head-inserted
// object_list ordering exactly.
pub export fn obj_all_ids_newest(out_count: *usize) ?[*]i64 {
    const ids = obj_all_ids(out_count) orelse return null;
    std.mem.sort(i64, ids[0..out_count.*], {}, std.sort.desc(i64));
    return ids;
}

const ObjProtoIterator = struct {
    iter: ObjProtoMap.Iterator,
};

const ObjIterator = struct {
    iter: std.AutoHashMap(i64, *cdb.obj_data).ValueIterator,
};

pub export fn obj_iterator_create() ?*anyopaque {
    const iterator = allocator.create(ObjIterator) catch return null;
    iterator.* = .{ .iter = objs_by_id.valueIterator() };
    return iterator;
}

pub export fn obj_next(iterator_ptr: ?*anyopaque) ?*cdb.obj_data {
    const iterator: *ObjIterator = @ptrCast(@alignCast(iterator_ptr orelse return null));
    return (iterator.iter.next() orelse return null).*;
}

pub export fn obj_iterator_free(iterator_ptr: ?*anyopaque) void {
    const iterator = iterator_ptr orelse return;
    allocator.destroy(@as(*ObjIterator, @ptrCast(@alignCast(iterator))));
}

pub export fn obj_proto_iterator_create() ?*anyopaque {
    const iterator = allocator.create(ObjProtoIterator) catch return null;
    iterator.* = .{ .iter = obj_proto_map.iterator() };
    return iterator;
}

pub export fn obj_proto_next(iterator_ptr: ?*anyopaque) ?*cdb.obj_proto_data {
    const iterator: *ObjProtoIterator = @ptrCast(@alignCast(iterator_ptr orelse return null));
    while (iterator.iter.next()) |entry| {
        if (entry.value_ptr.*.proto) |ptr| {
            return ptr;
        }
    }
    return null;
}

pub export fn obj_proto_iterator_free(iterator_ptr: ?*anyopaque) void {
    const iterator = iterator_ptr orelse return;
    allocator.destroy(@as(*ObjProtoIterator, @ptrCast(@alignCast(iterator))));
}

pub export fn obj_proto_get(vnum: cdb.obj_vnum) ?*cdb.obj_proto_data {
    return if (obj_proto_map.get(vnum)) |entry| entry.proto else null;
}

pub export fn obj_proto_count() usize {
    var total: usize = 0;
    var it = obj_proto_map.valueIterator();
    while (it.next()) |entry| {
        if (entry.*.proto != null) total += 1;
    }
    return total;
}

pub export fn obj_proto_put(vnum: cdb.obj_vnum, obj: ?*cdb.obj_proto_data) void {
    if (obj) |ptr| {
        const entry = obj_proto_map.getOrPut(vnum) catch return;
        if (!entry.found_existing) {
            entry.value_ptr.* = .{ .proto = ptr };
            return;
        }
        entry.value_ptr.*.proto = ptr;
        return;
    }

    if (obj_proto_map.getPtr(vnum)) |entry| {
        entry.proto = null;
        entry.special = null;
        if (entry.count == 0) {
            _ = obj_proto_map.remove(vnum);
        }
    }
}

pub export fn obj_proto_delete(vnum: cdb.obj_vnum) void {
    if (obj_proto_map.getPtr(vnum)) |entry| {
        entry.proto = null;
        entry.special = null;
        if (entry.count == 0) {
            _ = obj_proto_map.remove(vnum);
        }
    }
}

pub export fn obj_proto_special_get(vnum: cdb.obj_vnum) cdb.SpecialFunc {
    return if (obj_proto_map.get(vnum)) |entry| entry.special else null;
}

pub export fn obj_proto_special_set(vnum: cdb.obj_vnum, func: cdb.SpecialFunc) void {
    const entry = obj_proto_map.getOrPut(vnum) catch return;
    if (!entry.found_existing) {
        entry.value_ptr.* = .{ .special = func };
        return;
    }
    entry.value_ptr.*.special = func;
}

pub export fn obj_proto_count_increment(vnum: cdb.obj_vnum) void {
    const entry = obj_proto_map.getOrPut(vnum) catch return;
    if (!entry.found_existing) {
        entry.value_ptr.* = .{ .count = 1 };
        return;
    }
    entry.value_ptr.*.count += 1;
}

pub export fn obj_proto_count_get(vnum: cdb.obj_vnum) usize {
    return if (obj_proto_map.get(vnum)) |entry| entry.count else 0;
}

pub export fn obj_proto_count_decrement(vnum: cdb.obj_vnum) void {
    const entry = obj_proto_map.getPtr(vnum) orelse return;
    if (entry.count == 0) return;
    entry.count -= 1;
    if (entry.count == 0 and entry.proto == null and entry.special == null) {
        _ = obj_proto_map.remove(vnum);
    }
}

// --- Object contents tracking ---

pub export fn obj_contents_add(container: *cdb.obj_data, obj: *cdb.obj_data) void {
    const container_id = cdb.obj_id_get(container);
    const obj_id = cdb.obj_id_get(obj);
    const entry = obj_contents_map.getOrPut(container_id) catch return;
    if (!entry.found_existing) entry.value_ptr.* = IdList.empty;
    entry.value_ptr.append(allocator, obj_id) catch {};
}

pub export fn obj_contents_remove(container: *cdb.obj_data, obj: *cdb.obj_data) void {
    const container_id = cdb.obj_id_get(container);
    const obj_id = cdb.obj_id_get(obj);
    const list = obj_contents_map.getPtr(container_id) orelse return;
    for (list.items, 0..) |item, i| {
        if (item == obj_id) {
            _ = list.swapRemove(i);
            return;
        }
    }
}

pub export fn obj_contents_ids(container: *cdb.obj_data, out_count: *usize) ?[*]i64 {
    const container_id = cdb.obj_id_get(container);
    const list = obj_contents_map.getPtr(container_id) orelse {
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

pub export fn obj_contents_ids_free(ptr: ?[*]i64) void {
    std.c.free(@as(?*anyopaque, @ptrCast(ptr)));
}

pub export fn obj_contents_count(container: *cdb.obj_data) usize {
    const container_id = cdb.obj_id_get(container);
    const list = obj_contents_map.getPtr(container_id) orelse return 0;
    return list.items.len;
}

pub export fn obj_contents_first(container: *cdb.obj_data) ?*cdb.obj_data {
    const container_id = cdb.obj_id_get(container);
    const list = obj_contents_map.getPtr(container_id) orelse return null;
    if (list.items.len == 0) return null;
    return cdb.obj_by_id(list.items[0]);
}

fn unsubscribe(id: i64, name: []const u8) void {
    removeIdFromList(id, name);
}

fn removeIdFromList(id: i64, name: []const u8) void {
    const id_set = subscriptions_by_list.getPtr(name) orelse return;
    _ = id_set.remove(id);

    if (id_set.count() == 0) {
        id_set.deinit();
        if (subscriptions_by_list.fetchRemove(name)) |removed| {
            allocator.free(removed.key);
        }
    }
}

fn deinitSubscriptions() void {
    var list_it = subscriptions_by_list.iterator();
    while (list_it.next()) |entry| {
        allocator.free(entry.key_ptr.*);
        entry.value_ptr.deinit();
    }
    subscriptions_by_list.deinit();
}

fn listNameSlice(list_name: ?[*:0]const u8) ?[]const u8 {
    const ptr = list_name orelse return null;
    return std.mem.span(ptr);
}
