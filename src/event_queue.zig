const std = @import("std");
const cdb = @import("cdb");
const lua_api = @import("lua_api.zig");
const intern_mod = @import("intern.zig");
const zlua = @import("zlua");

const Lua = zlua.Lua;

// Context type tags — mirrored in event_queue_api.h
pub const CTX_NONE: c_int = 0;
pub const CTX_CHAR_ID: c_int = 1;
pub const CTX_OBJ_ID: c_int = 2;
pub const CTX_ZONE_ID: c_int = 3;
pub const CTX_ROOM_ID: c_int = 4;
pub const CTX_PAIR: c_int = 5;
pub const CTX_LUA_TABLE: c_int = 6;

pub const EventContext = union(enum) {
    none,
    char_id: i64,
    obj_id: i64,
    zone_id: cdb.zone_vnum,
    room_id: cdb.room_vnum,
    pair: struct { a: i64, b: i64 },
    lua_table_ref: c_int, // Lua registry ref; released when event fires or is cancelled
    // descriptor_id: u64 — add when descriptor_data gets a stable ID
};

pub const EventHandler = union(enum) {
    c_fn: *const fn (c_int, i64, i64) callconv(.c) void,
    lua_named: intern_mod.InternedId, // interned dotted path, e.g. "dbat.events.point_update"
};

const Event = struct {
    fire_at: i64, // std.time.milliTimestamp() — absolute wall time in ms
    id: u64, // returned to caller; used for cancellation
    handler: EventHandler,
    context: EventContext,
    interval: i64, // 0 = one-shot; >0 = ms between recurrences
};

fn compareEvents(_: void, a: Event, b: Event) std.math.Order {
    return std.math.order(a.fire_at, b.fire_at);
}

const Queue = std.PriorityQueue(Event, void, compareEvents);
const CancelSet = std.AutoHashMap(u64, void);

var gpa: std.mem.Allocator = undefined;
var io_handle: std.Io = undefined;
var queue: Queue = undefined;
var cancel_set: CancelSet = undefined;
var next_id: u64 = 1;

pub fn init(allocator: std.mem.Allocator, io: std.Io) void {
    gpa = allocator;
    io_handle = io;
    queue = Queue.initContext({});
    cancel_set = CancelSet.init(allocator);
}

fn nowMs() i64 {
    const ns = std.Io.Timestamp.now(io_handle, .awake).nanoseconds;
    return @intCast(@divTrunc(ns, std.time.ns_per_ms));
}

pub fn deinit() void {
    while (queue.pop()) |e| {
        releaseContext(e.context);
    }
    queue.deinit(gpa);
    cancel_set.deinit();
}

pub fn peekDeadline() ?i64 {
    return if (queue.peek()) |e| e.fire_at else null;
}

pub fn process(now_ms: i64) void {
    while (queue.peek()) |top| {
        if (top.fire_at > now_ms) break;
        const e = queue.pop().?; // safe: we just peeked and it's non-null

        if (cancel_set.contains(e.id)) {
            _ = cancel_set.remove(e.id);
            releaseContext(e.context);
            continue;
        }

        fireEvent(e);

        if (e.interval > 0) {
            var next = e;
            next.fire_at = e.fire_at + e.interval;
            next.id = newId();
            // context is reused in the rescheduled event — do not release
            queue.push(gpa, next) catch {};
        } else {
            releaseContext(e.context);
        }
    }
}

fn newId() u64 {
    const id = next_id;
    next_id +%= 1;
    return id;
}

fn releaseContext(ctx: EventContext) void {
    switch (ctx) {
        .lua_table_ref => |ref| lua_api.state().unref(zlua.registry_index, ref),
        else => {},
    }
}

fn contextToC(ctx: EventContext) struct { c_int, i64, i64 } {
    return switch (ctx) {
        .none => .{ CTX_NONE, 0, 0 },
        .char_id => |id| .{ CTX_CHAR_ID, id, 0 },
        .obj_id => |id| .{ CTX_OBJ_ID, id, 0 },
        .zone_id => |id| .{ CTX_ZONE_ID, @as(i64, id), 0 },
        .room_id => |id| .{ CTX_ROOM_ID, @as(i64, id), 0 },
        .pair => |p| .{ CTX_PAIR, p.a, p.b },
        .lua_table_ref => |ref| .{ CTX_LUA_TABLE, @as(i64, ref), 0 },
    };
}

fn contextFromC(ctx_type: c_int, ctx_a: i64, ctx_b: i64) EventContext {
    return switch (ctx_type) {
        CTX_CHAR_ID => .{ .char_id = ctx_a },
        CTX_OBJ_ID => .{ .obj_id = ctx_a },
        CTX_ZONE_ID => .{ .zone_id = @intCast(ctx_a) },
        CTX_ROOM_ID => .{ .room_id = @intCast(ctx_a) },
        CTX_PAIR => .{ .pair = .{ .a = ctx_a, .b = ctx_b } },
        CTX_LUA_TABLE => .{ .lua_table_ref = @intCast(ctx_a) },
        else => .none,
    };
}

fn fireEvent(e: Event) void {
    const ctype, const ca, const cb = contextToC(e.context);
    switch (e.handler) {
        .c_fn => |f| f(ctype, ca, cb),
        .lua_named => |id| fireLuaNamed(id, ctype, ca, cb),
    }
}

// Navigates a dotted path (e.g. "dbat.events.point_update") and calls it with
// (ctx_type, ctx_a, ctx_b). If any segment is missing or the final value is not
// a function, the event silently does nothing (expected during hot reload gaps).
fn fireLuaNamed(handler_id: intern_mod.InternedId, ctype: c_int, ca: i64, cb: i64) void {
    const lua = lua_api.state();
    const initial_top = lua.getTop();
    defer lua.setTop(initial_top);

    const name = intern_mod.nameOf(handler_id);
    var buf: [128]u8 = undefined;
    var iter = std.mem.splitScalar(u8, name, '.');

    const first = iter.next() orelse return;
    const first_z = std.fmt.bufPrintZ(&buf, "{s}", .{first}) catch return;
    if (lua.getGlobal(first_z) == .nil) return;

    while (iter.next()) |segment| {
        const seg_z = std.fmt.bufPrintZ(&buf, "{s}", .{segment}) catch return;
        if (lua.getField(-1, seg_z) == .nil) return;
    }

    if (lua.typeOf(-1) != .function) return;

    lua.pushInteger(ctype);
    lua.pushInteger(ca);
    lua.pushInteger(cb);
    lua.protectedCall(.{ .args = 3, .results = 0 }) catch |err| {
        const msg = lua.toString(-1) catch @errorName(err);
        std.log.err("event '{s}' failed: {s}", .{ name, msg });
        lua.pop(1);
    };
}

// --- C-callable API ---

pub export fn event_schedule_lua(
    fire_at: i64,
    interval: i64,
    name: ?[*:0]const u8,
    ctx_type: c_int,
    ctx_a: i64,
    ctx_b: i64,
) u64 {
    const n = name orelse return 0;
    const id = newId();
    const handler_id = intern_mod.intern(std.mem.span(n));
    queue.push(gpa, .{
        .fire_at = fire_at,
        .id = id,
        .handler = .{ .lua_named = handler_id },
        .context = contextFromC(ctx_type, ctx_a, ctx_b),
        .interval = interval,
    }) catch return 0;
    return id;
}

pub export fn event_schedule_c(
    fire_at: i64,
    interval: i64,
    handler_fn: ?*const fn (c_int, i64, i64) callconv(.c) void,
    ctx_type: c_int,
    ctx_a: i64,
    ctx_b: i64,
) u64 {
    const f = handler_fn orelse return 0;
    const id = newId();
    queue.push(gpa, .{
        .fire_at = fire_at,
        .id = id,
        .handler = .{ .c_fn = f },
        .context = contextFromC(ctx_type, ctx_a, ctx_b),
        .interval = interval,
    }) catch return 0;
    return id;
}

pub export fn eq_cancel(id: u64) void {
    cancel_set.put(id, {}) catch {};
}

pub export fn eq_remaining_ms(id: u64) i64 {
    if (id == 0 or cancel_set.contains(id)) return -1;
    for (queue.items) |e| {
        if (e.id == id) return e.fire_at - nowMs();
    }
    return -1;
}

pub export fn event_queue_now_ms() i64 {
    return nowMs();
}
