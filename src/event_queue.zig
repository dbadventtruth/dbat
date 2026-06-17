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
    lua_entity_update: intern_mod.InternedId, // interned kind string; fires entity:on_update(kind)
};

// Registered by game.zig at startup. Receives (kind, ctx_type, entity_id).
// Kept as a plain function pointer to avoid circular imports between event_queue ↔ entity lua modules.
var entity_update_fn: ?*const fn ([]const u8, c_int, i64) void = null;

pub fn setEntityUpdateFn(f: *const fn ([]const u8, c_int, i64) void) void {
    entity_update_fn = f;
}

// Owner kinds — mirrored in event_queue_api.h
pub const OWNER_NONE: u8 = 0;
pub const OWNER_CHAR: u8 = 1;
pub const OWNER_OBJ: u8 = 2;
pub const OWNER_ROOM: u8 = 3;
pub const OWNER_ZONE: u8 = 4;
pub const OWNER_TRIG: u8 = 5;

pub const OwnerKey = struct {
    kind: u8,
    id: i64,
};

const no_owner = OwnerKey{ .kind = OWNER_NONE, .id = 0 };

const Event = struct {
    fire_at: i64, // absolute wall time in ms (event_queue_now_ms())
    id: u64, // returned to caller; used for cancellation
    handler: EventHandler,
    context: EventContext,
    interval: i64, // 0 = one-shot; >0 = ms between recurrences
    owner: OwnerKey, // entity this event belongs to; no_owner if unowned
    tag: intern_mod.InternedId, // event kind, e.g. "fish_tick"; INVALID_ID if untagged
};

// Side table entry for every pending event — answers "is id pending?",
// "when does it fire?", and "who owns it?" without touching the heap.
const EventMeta = struct {
    fire_at: i64,
    owner: OwnerKey,
    tag: intern_mod.InternedId,
};

fn compareEvents(_: void, a: Event, b: Event) std.math.Order {
    return std.math.order(a.fire_at, b.fire_at);
}

const Queue = std.PriorityQueue(Event, void, compareEvents);
const CancelSet = std.AutoHashMap(u64, void);
const PendingMap = std.AutoHashMap(u64, EventMeta);
const IdSet = std.AutoHashMap(u64, void);
const OwnerIndex = std.AutoHashMap(OwnerKey, IdSet);

var gpa: std.mem.Allocator = undefined;
var io_handle: std.Io = undefined;
var queue: Queue = undefined;
var cancel_set: CancelSet = undefined;
var pending_by_id: PendingMap = undefined;
var ids_by_owner: OwnerIndex = undefined;
var next_id: u64 = 1;

pub fn init(allocator: std.mem.Allocator, io: std.Io) void {
    gpa = allocator;
    io_handle = io;
    queue = Queue.initContext({});
    cancel_set = CancelSet.init(allocator);
    pending_by_id = PendingMap.init(allocator);
    ids_by_owner = OwnerIndex.init(allocator);
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
    pending_by_id.deinit();
    var it = ids_by_owner.valueIterator();
    while (it.next()) |set| set.deinit();
    ids_by_owner.deinit();
}

// Registers the event in the heap plus both side tables.
fn enqueue(e: Event) !void {
    try queue.push(gpa, e);
    pending_by_id.put(e.id, .{
        .fire_at = e.fire_at,
        .owner = e.owner,
        .tag = e.tag,
    }) catch |err| {
        // Heap entry without metadata would desync the maps; back it out.
        for (queue.items, 0..) |item, i| {
            if (item.id == e.id) {
                _ = queue.popIndex(i);
                break;
            }
        }
        return err;
    };
    if (e.owner.kind != OWNER_NONE) {
        indexOwner(e.owner, e.id) catch |err| {
            _ = pending_by_id.remove(e.id);
            for (queue.items, 0..) |item, i| {
                if (item.id == e.id) {
                    _ = queue.popIndex(i);
                    break;
                }
            }
            return err;
        };
    }
}

fn indexOwner(owner: OwnerKey, id: u64) !void {
    const entry = try ids_by_owner.getOrPut(owner);
    if (!entry.found_existing) entry.value_ptr.* = IdSet.init(gpa);
    try entry.value_ptr.put(id, {});
}

// Removes an event from the side tables (not the heap — that drains lazily).
fn dropMeta(id: u64) void {
    const kv = pending_by_id.fetchRemove(id) orelse return;
    const owner = kv.value.owner;
    if (owner.kind == OWNER_NONE) return;
    if (ids_by_owner.getPtr(owner)) |set| {
        _ = set.remove(id);
        if (set.count() == 0) {
            set.deinit();
            _ = ids_by_owner.remove(owner);
        }
    }
}

pub fn peekDeadline() ?i64 {
    return if (queue.peek()) |e| e.fire_at else null;
}

pub fn process(now_ms: i64) void {
    while (queue.peek()) |top| {
        if (top.fire_at > now_ms) break;
        const e = queue.pop().?; // safe: we just peeked and it's non-null

        if (cancel_set.contains(e.id)) {
            // eq_cancel already dropped this id from the side tables.
            _ = cancel_set.remove(e.id);
            releaseContext(e.context);
            continue;
        }

        // Drop metadata before firing so the handler sees a consistent view
        // (it may schedule, cancel, or reschedule events — including its own id,
        // which is no longer pending and must no-op).
        dropMeta(e.id);

        const t0 = nowMs();
        fireEvent(e);
        const elapsed_ms: c_int = @intCast(@min(nowMs() - t0, 999_999));
        if (elapsed_ms >= 500) logSlowEvent(e.handler, elapsed_ms);

        if (e.interval > 0) {
            var next = e;
            next.fire_at = e.fire_at + e.interval;
            next.id = newId();
            // context is reused in the rescheduled event — do not release
            enqueue(next) catch releaseContext(e.context);
        } else {
            releaseContext(e.context);
        }
    }
}

fn logSlowEvent(handler: EventHandler, elapsed_ms: c_int) void {
    switch (handler) {
        .c_fn => |f| cdb.mud_log(
            "PERF: event [c_fn 0x%lx] took %dms",
            @as(c_ulong, @intCast(@intFromPtr(f))),
            elapsed_ms,
        ),
        .lua_named => |id| {
            const name = intern_mod.nameOf(id);
            cdb.mud_log(
                "PERF: event '%.*s' took %dms",
                @as(c_int, @intCast(name.len)),
                name.ptr,
                elapsed_ms,
            );
        },
        .lua_entity_update => |id| {
            const name = intern_mod.nameOf(id);
            cdb.mud_log(
                "PERF: on_update '%.*s' took %dms",
                @as(c_int, @intCast(name.len)),
                name.ptr,
                elapsed_ms,
            );
        },
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
        .lua_entity_update => |kind_id| fireLuaEntityUpdate(kind_id, e.context),
    }
}

fn fireLuaEntityUpdate(kind_id: intern_mod.InternedId, ctx: EventContext) void {
    const f = entity_update_fn orelse return;
    const kind = intern_mod.nameOf(kind_id);
    switch (ctx) {
        .char_id  => |id| f(kind, CTX_CHAR_ID,  id),
        .room_id  => |id| f(kind, CTX_ROOM_ID,  @as(i64, id)),
        .obj_id   => |id| f(kind, CTX_OBJ_ID,   id),
        .zone_id  => |id| f(kind, CTX_ZONE_ID,  @as(i64, id)),
        else      => {},
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

fn schedule(
    fire_at: i64,
    interval: i64,
    handler: EventHandler,
    context: EventContext,
    owner: OwnerKey,
    tag: intern_mod.InternedId,
) u64 {
    // Owned events must be tagged or the owner index can't answer "what kind?".
    if (owner.kind != OWNER_NONE and tag == intern_mod.INVALID_ID) {
        std.log.err("event_queue: owned event (kind {d}, id {d}) scheduled without a tag", .{ owner.kind, owner.id });
        return 0;
    }
    const id = newId();
    enqueue(.{
        .fire_at = fire_at,
        .id = id,
        .handler = handler,
        .context = context,
        .interval = interval,
        .owner = owner,
        .tag = tag,
    }) catch return 0;
    return id;
}

fn ownerFromC(owner_kind: c_int, owner_id: i64) OwnerKey {
    if (owner_kind <= 0) return no_owner;
    return .{ .kind = @intCast(owner_kind), .id = owner_id };
}

fn tagFromC(tag: ?[*:0]const u8) intern_mod.InternedId {
    const t = tag orelse return intern_mod.INVALID_ID;
    return intern_mod.intern(std.mem.span(t));
}

// Cancels every pending event for owner; tag null = all kinds.
// Returns the number of events cancelled. Callable from other Zig modules.
pub fn cancelOwner(kind: u8, owner_id: i64, tag: ?[]const u8) i64 {
    const owner = OwnerKey{ .kind = kind, .id = owner_id };
    const set = ids_by_owner.getPtr(owner) orelse return 0;
    // Filter tag via lookup: a never-interned tag can't match anything.
    const want_tag: ?intern_mod.InternedId = if (tag) |t|
        (intern_mod.lookup(t) orelse return 0)
    else
        null;

    var to_cancel = std.array_list.Managed(u64).init(gpa);
    defer to_cancel.deinit();
    var it = set.keyIterator();
    while (it.next()) |id| {
        if (want_tag) |wt| {
            const meta = pending_by_id.get(id.*) orelse continue;
            if (meta.tag != wt) continue;
        }
        to_cancel.append(id.*) catch return 0;
    }
    for (to_cancel.items) |id| eq_cancel(id);
    return @intCast(to_cancel.items.len);
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
    const handler_id = intern_mod.intern(std.mem.span(n));
    return schedule(fire_at, interval, .{ .lua_named = handler_id }, contextFromC(ctx_type, ctx_a, ctx_b), no_owner, intern_mod.INVALID_ID);
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
    return schedule(fire_at, interval, .{ .c_fn = f }, contextFromC(ctx_type, ctx_a, ctx_b), no_owner, intern_mod.INVALID_ID);
}

pub export fn event_schedule_lua_owned(
    fire_at: i64,
    interval: i64,
    name: ?[*:0]const u8,
    ctx_type: c_int,
    ctx_a: i64,
    ctx_b: i64,
    owner_kind: c_int,
    owner_id: i64,
    tag: ?[*:0]const u8,
) u64 {
    const n = name orelse return 0;
    const handler_id = intern_mod.intern(std.mem.span(n));
    return schedule(fire_at, interval, .{ .lua_named = handler_id }, contextFromC(ctx_type, ctx_a, ctx_b), ownerFromC(owner_kind, owner_id), tagFromC(tag));
}

pub export fn event_schedule_c_owned(
    fire_at: i64,
    interval: i64,
    handler_fn: ?*const fn (c_int, i64, i64) callconv(.c) void,
    ctx_type: c_int,
    ctx_a: i64,
    ctx_b: i64,
    owner_kind: c_int,
    owner_id: i64,
    tag: ?[*:0]const u8,
) u64 {
    const f = handler_fn orelse return 0;
    return schedule(fire_at, interval, .{ .c_fn = f }, contextFromC(ctx_type, ctx_a, ctx_b), ownerFromC(owner_kind, owner_id), tagFromC(tag));
}

pub export fn eq_cancel(id: u64) void {
    // Only pending events are marked; stale/duplicate cancels are pure no-ops,
    // so cancel_set can never accumulate entries that no pop will consume.
    if (!pending_by_id.contains(id)) return;
    cancel_set.put(id, {}) catch return;
    dropMeta(id);
}

pub export fn eq_cancel_owner(owner_kind: c_int, owner_id: i64, tag: ?[*:0]const u8) i64 {
    if (owner_kind <= 0) return 0;
    const t: ?[]const u8 = if (tag) |p| std.mem.span(p) else null;
    return cancelOwner(@intCast(owner_kind), owner_id, t);
}

pub export fn eq_owner_count(owner_kind: c_int, owner_id: i64, tag: ?[*:0]const u8) i64 {
    if (owner_kind <= 0) return 0;
    const owner = OwnerKey{ .kind = @intCast(owner_kind), .id = owner_id };
    const set = ids_by_owner.getPtr(owner) orelse return 0;
    const want_tag: ?intern_mod.InternedId = if (tag) |p|
        (intern_mod.lookup(std.mem.span(p)) orelse return 0)
    else
        null;
    if (want_tag == null) return @intCast(set.count());

    var n: i64 = 0;
    var it = set.keyIterator();
    while (it.next()) |id| {
        const meta = pending_by_id.get(id.*) orelse continue;
        if (meta.tag == want_tag.?) n += 1;
    }
    return n;
}

pub export fn eq_owner_next_ms(owner_kind: c_int, owner_id: i64, tag: ?[*:0]const u8) i64 {
    if (owner_kind <= 0) return -1;
    const owner = OwnerKey{ .kind = @intCast(owner_kind), .id = owner_id };
    const set = ids_by_owner.getPtr(owner) orelse return -1;
    const want_tag: ?intern_mod.InternedId = if (tag) |p|
        (intern_mod.lookup(std.mem.span(p)) orelse return -1)
    else
        null;

    var soonest: ?i64 = null;
    var it = set.keyIterator();
    while (it.next()) |id| {
        const meta = pending_by_id.get(id.*) orelse continue;
        if (want_tag) |wt| {
            if (meta.tag != wt) continue;
        }
        if (soonest == null or meta.fire_at < soonest.?) soonest = meta.fire_at;
    }
    const fire_at = soonest orelse return -1;
    return @max(0, fire_at - nowMs());
}

pub export fn eq_reschedule(id: u64, new_fire_at: i64) c_int {
    const meta = pending_by_id.getPtr(id) orelse return -1;
    for (queue.items, 0..) |e, i| {
        if (e.id != id) continue;
        var moved = queue.popIndex(i);
        moved.fire_at = new_fire_at;
        queue.push(gpa, moved) catch {
            // Heap entry is gone; clean the side tables so the id reads as dead.
            dropMeta(id);
            releaseContext(moved.context);
            return -1;
        };
        meta.fire_at = new_fire_at;
        return 0;
    }
    return -1;
}

pub export fn eq_remaining_ms(id: u64) i64 {
    const meta = pending_by_id.get(id) orelse return -1;
    return @max(0, meta.fire_at - nowMs());
}

pub export fn event_queue_now_ms() i64 {
    return nowMs();
}

// Schedule a lua_entity_update event for a character.
// kind is the colon-separated routing string, e.g. "condition:bonus_healthy:tick".
// It is also used as the owner-index tag for cancellation.
pub export fn event_schedule_lua_char_update(fire_at: i64, interval: i64, kind: ?[*:0]const u8, char_id: i64) u64 {
    const k = kind orelse return 0;
    const kind_span = std.mem.span(k);
    const kind_id = intern_mod.intern(kind_span);
    const owner = OwnerKey{ .kind = OWNER_CHAR, .id = char_id };
    return schedule(fire_at, interval, .{ .lua_entity_update = kind_id }, .{ .char_id = char_id }, owner, kind_id);
}

pub export fn event_schedule_lua_room_update(fire_at: i64, interval: i64, kind: ?[*:0]const u8, room_id: cdb.room_vnum) u64 {
    const k = kind orelse return 0;
    const kind_span = std.mem.span(k);
    const kind_id = intern_mod.intern(kind_span);
    const owner = OwnerKey{ .kind = OWNER_ROOM, .id = @as(i64, room_id) };
    return schedule(fire_at, interval, .{ .lua_entity_update = kind_id }, .{ .room_id = room_id }, owner, kind_id);
}

pub export fn event_schedule_lua_obj_update(fire_at: i64, interval: i64, kind: ?[*:0]const u8, obj_id: i64) u64 {
    const k = kind orelse return 0;
    const kind_span = std.mem.span(k);
    const kind_id = intern_mod.intern(kind_span);
    const owner = OwnerKey{ .kind = OWNER_OBJ, .id = obj_id };
    return schedule(fire_at, interval, .{ .lua_entity_update = kind_id }, .{ .obj_id = obj_id }, owner, kind_id);
}

pub export fn event_schedule_lua_zone_update(fire_at: i64, interval: i64, kind: ?[*:0]const u8, zone_id: cdb.zone_vnum) u64 {
    const k = kind orelse return 0;
    const kind_span = std.mem.span(k);
    const kind_id = intern_mod.intern(kind_span);
    const owner = OwnerKey{ .kind = OWNER_ZONE, .id = @as(i64, zone_id) };
    return schedule(fire_at, interval, .{ .lua_entity_update = kind_id }, .{ .zone_id = zone_id }, owner, kind_id);
}
