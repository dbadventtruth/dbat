const std = @import("std");
const characters = @cImport(@cInclude("dbat/db/characters.h"));
const objects = @cImport(@cInclude("dbat/db/objects.h"));
const rooms = @cImport(@cInclude("dbat/db/rooms.h"));

const Allocator = std.mem.Allocator;
const CountersPath = "data/counters.json";

const DbCounters = struct {
    next_char_id: i64 = 1,
    next_obj_id: i64 = 1,
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator: Allocator = undefined;
var initialized = false;

var characters_by_id: std.AutoHashMap(i64, *characters.char_data) = undefined;
var objects_by_id: std.AutoHashMap(i64, *objects.obj_data) = undefined;
var rooms_by_id: std.AutoHashMap(rooms.room_vnum, *rooms.room_data) = undefined;

var mob_counts: std.AutoHashMap(characters.mob_vnum, usize) = undefined;
var object_counts: std.AutoHashMap(objects.obj_vnum, usize) = undefined;

var next_char_id: i64 = 1;
var next_obj_id: i64 = 1;

fn sanitizeNextId(value: i64) i64 {
    return if (value < 1) 1 else value;
}

pub export fn db_init() void {
    if (initialized) return;

    allocator = gpa.allocator();
    characters_by_id = std.AutoHashMap(i64, *characters.char_data).init(allocator);
    objects_by_id = std.AutoHashMap(i64, *objects.obj_data).init(allocator);
    rooms_by_id = std.AutoHashMap(rooms.room_vnum, *rooms.room_data).init(allocator);

    mob_counts = std.AutoHashMap(characters.mob_vnum, usize).init(allocator);
    object_counts = std.AutoHashMap(objects.obj_vnum, usize).init(allocator);

    initialized = true;
    db_load_counters();
}

pub export fn db_cleanup() void {
    if (!initialized) return;

    db_save_counters();

    characters_by_id.deinit();
    objects_by_id.deinit();
    rooms_by_id.deinit();
    mob_counts.deinit();
    object_counts.deinit();

    _ = gpa.deinit();
    initialized = false;
}

pub export fn db_load_counters() void {
    if (!initialized) db_init();

    next_char_id = 1;
    next_obj_id = 1;

    const file = std.fs.cwd().openFile(CountersPath, .{}) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return,
    };
    defer file.close();

    const contents = file.readToEndAlloc(allocator, 1024 * 1024) catch return;
    defer allocator.free(contents);

    const parsed = std.json.parseFromSlice(DbCounters, allocator, contents, .{}) catch return;
    defer parsed.deinit();

    next_char_id = sanitizeNextId(parsed.value.next_char_id);
    next_obj_id = sanitizeNextId(parsed.value.next_obj_id);
}

pub export fn db_save_counters() void {
    if (!initialized) return;

    std.fs.cwd().makePath("data") catch return;

    const file = std.fs.cwd().createFile(CountersPath, .{ .truncate = true }) catch return;
    defer file.close();

    const counters = DbCounters{
        .next_char_id = sanitizeNextId(next_char_id),
        .next_obj_id = sanitizeNextId(next_obj_id),
    };

    std.json.stringify(counters, .{ .whitespace = .indent_2 }, file.writer()) catch return;
    file.writer().writeByte('\n') catch return;
}

pub export fn char_game_create() ?*characters.char_data {
    if (!initialized) db_init();
    const ch = allocator.create(characters.char_data) catch return null;
    ch.* = std.mem.zeroes(characters.char_data);

    return ch;
}

pub export fn char_game_destroy(ch: ?*characters.char_data) void {
    if (!initialized) return;
    const ptr = ch orelse return;
    allocator.destroy(ptr);
}

pub export fn char_game_nextid() i64 {
    if (!initialized) db_init();
    const id = next_char_id;
    next_char_id += 1;
    return id;
}

pub export fn char_game_activate(ch: ?*characters.char_data) void {
    if (!initialized) db_init();
    const ptr = ch orelse return;

    const char_id = @as(i64, ptr.id);
    if (char_id >= next_char_id) {
        next_char_id = char_id + 1;
    }

    characters_by_id.put(char_id, ptr) catch return;

    const count = mob_counts.getOrPut(ptr.nr) catch return;
    if (count.found_existing) {
        count.value_ptr.* += 1;
    } else {
        count.value_ptr.* = 1;
    }
}

pub export fn char_game_deactivate(ch: ?*characters.char_data) void {
    if (!initialized) return;
    const ptr = ch orelse return;

    _ = characters_by_id.remove(@as(i64, ptr.id));

    if (mob_counts.getPtr(ptr.nr)) |count_ptr| {
        if (count_ptr.* > 1) {
            count_ptr.* -= 1;
        } else {
            _ = mob_counts.remove(ptr.nr);
        }
    }
}

pub export fn char_by_id(id: i64) ?*characters.char_data {
    if (!initialized) return null;
    return characters_by_id.get(id);
}

pub export fn mob_vnum_count(vnum: characters.mob_vnum) usize {
    if (!initialized) return 0;
    return mob_counts.get(vnum) orelse 0;
}

pub export fn obj_game_create() ?*objects.obj_data {
    if (!initialized) db_init();
    const obj = allocator.create(objects.obj_data) catch return null;
    obj.* = std.mem.zeroes(objects.obj_data);

    return obj;
}

pub export fn obj_game_destroy(obj: ?*objects.obj_data) void {
    if (!initialized) return;
    const ptr = obj orelse return;
    allocator.destroy(ptr);
}

pub export fn obj_game_nextid() i64 {
    if (!initialized) db_init();
    const id = next_obj_id;
    next_obj_id += 1;
    return id;
}

pub export fn obj_game_activate(obj: ?*objects.obj_data) void {
    if (!initialized) db_init();
    const ptr = obj orelse return;

    const obj_id = @as(i64, ptr.id);
    if (obj_id >= next_obj_id) {
        next_obj_id = obj_id + 1;
    }

    objects_by_id.put(obj_id, ptr) catch return;

    const count = object_counts.getOrPut(ptr.item_number) catch return;
    if (count.found_existing) {
        count.value_ptr.* += 1;
    } else {
        count.value_ptr.* = 1;
    }
}

pub export fn obj_game_deactivate(obj: ?*objects.obj_data) void {
    if (!initialized) return;
    const ptr = obj orelse return;

    _ = objects_by_id.remove(@as(i64, ptr.id));

    if (object_counts.getPtr(ptr.item_number)) |count_ptr| {
        if (count_ptr.* > 1) {
            count_ptr.* -= 1;
        } else {
            _ = object_counts.remove(ptr.item_number);
        }
    }
}

pub export fn obj_by_id(id: i64) ?*objects.obj_data {
    if (!initialized) return null;
    return objects_by_id.get(id);
}

pub export fn obj_vnum_count(vnum: objects.obj_vnum) usize {
    if (!initialized) return 0;
    return object_counts.get(vnum) orelse 0;
}

pub export fn room_game_activate(room: ?*rooms.room_data, vnum: rooms.room_vnum) void {
    if (!initialized) db_init();
    const ptr = room orelse return;
    rooms_by_id.put(vnum, ptr) catch return;
}

pub export fn room_by_id(vnum: rooms.room_vnum) ?*rooms.room_data {
    if (!initialized) return null;
    return rooms_by_id.get(vnum);
}
