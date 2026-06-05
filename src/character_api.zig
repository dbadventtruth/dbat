const cdb = @import("cdb");
const std = @import("std");
const characters = @import("character.zig");
const bitflags = @import("flags.zig");
const obj_api = @import("object_api.zig");
const lua_api = @import("lua_api.zig");
const modifiers_api = @import("modifiers_api.zig");

pub const TransformData = struct {
    id: []const u8,
    numbers: std.StringHashMap(i64),
    strings: std.StringHashMap([]const u8),

    pub fn init(alloc: std.mem.Allocator, id: []const u8) !TransformData {
        return .{
            .id = lua_api.internString(id),
            .numbers = std.StringHashMap(i64).init(alloc),
            .strings = std.StringHashMap([]const u8).init(alloc),
        };
    }

    pub fn deinit(self: *TransformData, alloc: std.mem.Allocator) void {
        self.numbers.deinit();
        var string_it = self.strings.iterator();
        while (string_it.next()) |entry| {
            alloc.free(entry.value_ptr.*);
        }
        self.strings.deinit();
    }
};

const ConditionNumberArg = extern struct {
    key: ?[*:0]const u8,
    value: i64,
};

const ConditionStringArg = extern struct {
    key: ?[*:0]const u8,
    value: ?[*:0]const u8,
};

const DerivedData = struct {
    value: i64,
};

const SkillData = struct {
    base: i64,
    perf: i64,
};

pub const ConditionSource = struct {
    category: []const u8,
    id: []const u8,

    pub fn deinit(self: *ConditionSource, alloc: std.mem.Allocator) void {
        alloc.free(self.category);
        alloc.free(self.id);
    }
};

pub const ConditionInstance = struct {
    id: []const u8,
    stacks: i64 = 1,
    duration: i64 = -1,
    sources: std.array_list.Managed(ConditionSource),
    numbers: std.StringHashMap(i64),
    strings: std.StringHashMap([]const u8),

    pub fn init(alloc: std.mem.Allocator, id: []const u8) !ConditionInstance {
        return .{
            .id = lua_api.internString(id),
            .sources = std.array_list.Managed(ConditionSource).init(alloc),
            .numbers = std.StringHashMap(i64).init(alloc),
            .strings = std.StringHashMap([]const u8).init(alloc),
        };
    }

    pub fn deinit(self: *ConditionInstance, alloc: std.mem.Allocator) void {
        for (self.sources.items) |*source| source.deinit(alloc);
        self.sources.deinit();
        self.numbers.deinit();
        var string_it = self.strings.iterator();
        while (string_it.next()) |entry| {
            alloc.free(entry.value_ptr.*);
        }
        self.strings.deinit();
    }
};

const meter_scale: i64 = 1_000_000;

const stat_names = [_][]const u8{
    "agility",
    "alignment",
    "armor",
    "constitution",
    "death_count",
    "drunk",
    "experience",
    "fury",
    "height",
    "hunger",
    "intelligence",
    "kaioken",
    "ki",
    "level",
    "life_percent",
    "money",
    "money_bank",
    "molt_experience",
    "molt_level",
    "powerlevel",
    "practices",
    "skill_slots",
    "speed",
    "stamina",
    "strength",
    "suppression",
    "thirst",
    "train_agility",
    "train_constitution",
    "train_intelligence",
    "train_speed",
    "train_strength",
    "train_wisdom",
    "upgrades",
    "weight",
    "wisdom",
};

const derived_names = [_][]const u8{
    "agility",
    "armor",
    "autoskill_bonus",
    "constitution",
    "damage_bonus",
    "fish_pole_bonus",
    "height",
    "intelligence",
    "ki",
    "lifeforce",
    "powerlevel",
    "regen_bonus",
    "speed",
    "stamina",
    "strength",
    "weight",
    "wisdom",
};

const StatId = std.math.IntFittingRange(0, stat_names.len - 1);
const DerivedId = std.math.IntFittingRange(0, derived_names.len - 1);

const StatStorage = struct {
    values: [stat_names.len]i64 = [_]i64{0} ** stat_names.len,
    present: std.StaticBitSet(stat_names.len) = std.StaticBitSet(stat_names.len).initEmpty(),

    fn get(self: *const StatStorage, id: StatId) ?i64 {
        if (!self.present.isSet(id)) return null;
        return self.values[id];
    }

    fn set(self: *StatStorage, id: StatId, value: i64) void {
        self.values[id] = value;
        self.present.set(id);
    }

    fn clear(self: *StatStorage) void {
        self.values = [_]i64{0} ** stat_names.len;
        self.present = std.StaticBitSet(stat_names.len).initEmpty();
    }

    fn copyFrom(self: *StatStorage, other: *const StatStorage) void {
        self.values = other.values;
        self.present = other.present;
    }
};

fn statId(name: []const u8) ?StatId {
    inline for (stat_names, 0..) |stat_name, index| {
        if (std.mem.eql(u8, name, stat_name)) return @intCast(index);
    }
    return null;
}

const DerivedStorage = struct {
    values: [derived_names.len]DerivedData = [_]DerivedData{.{ .value = 0 }} ** derived_names.len,
    present: std.StaticBitSet(derived_names.len) = std.StaticBitSet(derived_names.len).initEmpty(),

    fn get(self: *const DerivedStorage, id: DerivedId) ?DerivedData {
        if (!self.present.isSet(id)) return null;
        return self.values[id];
    }

    fn set(self: *DerivedStorage, id: DerivedId, value: DerivedData) void {
        self.values[id] = value;
        self.present.set(id);
    }

    fn clear(self: *DerivedStorage) void {
        self.present = std.StaticBitSet(derived_names.len).initEmpty();
    }
};

fn derivedId(name: []const u8) ?DerivedId {
    inline for (derived_names, 0..) |derived_name, index| {
        if (std.mem.eql(u8, name, derived_name)) return @intCast(index);
    }
    return null;
}

pub const CharacterData = struct {
    stats: StatStorage,
    deriveds: DerivedStorage,
    modifiers: modifiers_api.ModifierCache,
    deriveds_dirty: bool,
    transforms: std.StringHashMap(TransformData),
    meters: std.StringHashMap(i64),
    skills: std.StringHashMap(SkillData),
    conditions: std.StringHashMap(ConditionInstance),

    pub fn init(alloc: std.mem.Allocator) CharacterData {
        return CharacterData{
            .stats = .{},
            .deriveds = .{},
            .modifiers = modifiers_api.ModifierCache.init(alloc),
            .deriveds_dirty = true,
            .transforms = std.StringHashMap(TransformData).init(alloc),
            .meters = std.StringHashMap(i64).init(alloc),
            .skills = std.StringHashMap(SkillData).init(alloc),
            .conditions = std.StringHashMap(ConditionInstance).init(alloc),
        };
    }

    pub fn deinit(self: *CharacterData) void {
        self.modifiers.deinit();
        var transforms = self.transforms.iterator();
        while (transforms.next()) |entry| {
            entry.value_ptr.deinit(std.heap.page_allocator);
        }
        self.transforms.deinit();
        self.meters.deinit();
        self.skills.deinit();
        var conditions = self.conditions.iterator();
        while (conditions.next()) |entry| {
            entry.value_ptr.deinit(std.heap.page_allocator);
        }
        self.conditions.deinit();
    }
};

pub const CharacterStatEntry = struct {
    name: []const u8,
    value: i64,
};

pub fn characterStatEntry(ch: *const cdb.char_data, index: usize) ?CharacterStatEntry {
    if (index >= stat_names.len) return null;
    const ptr = ch.zigdata orelse return null;
    const data: *const CharacterData = @ptrCast(@alignCast(ptr));
    const id: StatId = @intCast(index);
    if (!data.stats.present.isSet(id)) return null;
    return .{ .name = stat_names[index], .value = data.stats.values[index] };
}

pub fn characterStatCount() usize {
    return stat_names.len;
}

const MobProtoData = struct {
    stats: StatStorage,

    pub fn init(alloc: std.mem.Allocator) MobProtoData {
        _ = alloc;
        return .{ .stats = .{} };
    }

    pub fn deinit(self: *MobProtoData) void {
        _ = self;
    }
};

extern fn strdup(s: [*:0]const u8) ?[*:0]u8;

pub fn char_ensure_zigdata(ch: *cdb.char_data) ?*CharacterData {
    if (ch.zigdata == null) {
        const data = std.heap.page_allocator.create(CharacterData) catch return null;
        data.* = CharacterData.init(std.heap.page_allocator);
        ch.zigdata = data;
    }
    return @ptrCast(@alignCast(ch.zigdata.?));
}

pub export fn char_zig_free(ch: *cdb.char_data) void {
    if (ch.zigdata == null) return;
    const data: *CharacterData = @ptrCast(@alignCast(ch.zigdata.?));
    data.deinit();
    std.heap.page_allocator.destroy(data);
    ch.zigdata = null;
}

fn mobProtoEnsureZigdata(proto: *cdb.mob_proto_data) ?*MobProtoData {
    if (proto.zigdata == null) {
        const data = std.heap.page_allocator.create(MobProtoData) catch return null;
        data.* = MobProtoData.init(std.heap.page_allocator);
        proto.zigdata = data;
    }
    return @ptrCast(@alignCast(proto.zigdata.?));
}

pub export fn mob_proto_zig_free(proto: *cdb.mob_proto_data) void {
    if (proto.zigdata == null) return;
    const data: *MobProtoData = @ptrCast(@alignCast(proto.zigdata.?));
    data.deinit();
    std.heap.page_allocator.destroy(data);
    proto.zigdata = null;
}

pub export fn mob_proto_stat_get(proto: *cdb.mob_proto_data, stat: ?[*:0]const u8) i64 {
    const name = statName(stat) orelse return 0;
    const definition = lua_api.statDefinition(name) orelse return 0;
    const id = statId(name) orelse return 0;
    if (proto.zigdata) |ptr| {
        const data: *MobProtoData = @ptrCast(@alignCast(ptr));
        if (data.stats.get(id)) |value| return value;
    }
    return definition.default_value;
}

pub export fn mob_proto_stat_set(proto: *cdb.mob_proto_data, stat: ?[*:0]const u8, value: i64) i64 {
    const name = statName(stat) orelse return 0;
    const definition = lua_api.statDefinition(name) orelse return 0;
    const id = statId(name) orelse return 0;
    const clamped = clampStat(value, definition);
    const data = mobProtoEnsureZigdata(proto) orelse return 0;
    data.stats.set(id, clamped);
    return clamped;
}

pub export fn mob_proto_stat_mod(proto: *cdb.mob_proto_data, stat: ?[*:0]const u8, mod: i64) i64 {
    return mob_proto_stat_set(proto, stat, mob_proto_stat_get(proto, stat) + mod);
}

pub export fn mob_proto_stats_copy_to_char(proto: *cdb.mob_proto_data, ch: *cdb.char_data) void {
    const data = char_ensure_zigdata(ch) orelse return;
    data.stats.clear();
    if (proto.zigdata) |ptr| {
        const proto_data: *MobProtoData = @ptrCast(@alignCast(ptr));
        data.stats.copyFrom(&proto_data.stats);
    }
    copyMobProtoLegacyStatsToChar(proto, ch);
    invalidateDeriveds(data);
}

pub export fn char_stats_copy_to_mob_proto(ch: *cdb.char_data, proto: *cdb.mob_proto_data) void {
    const data = mobProtoEnsureZigdata(proto) orelse return;
    data.stats.clear();
    copyCharLegacyStatsToMobProto(ch, proto);
    if (ch.zigdata) |ptr| {
        const char_data: *CharacterData = @ptrCast(@alignCast(ptr));
        data.stats.copyFrom(&char_data.stats);
    }
}

fn copyMobProtoLegacyStatsToChar(proto: *cdb.mob_proto_data, ch: *cdb.char_data) void {
    _ = char_stat_set(ch, "strength", mob_proto_stat_get(proto, "strength"));
    _ = char_stat_set(ch, "intelligence", mob_proto_stat_get(proto, "intelligence"));
    _ = char_stat_set(ch, "wisdom", mob_proto_stat_get(proto, "wisdom"));
    _ = char_stat_set(ch, "agility", mob_proto_stat_get(proto, "agility"));
    _ = char_stat_set(ch, "constitution", mob_proto_stat_get(proto, "constitution"));
    _ = char_stat_set(ch, "speed", mob_proto_stat_get(proto, "speed"));
    _ = char_stat_set(ch, "height", mob_proto_stat_get(proto, "height"));
    _ = char_stat_set(ch, "weight", mob_proto_stat_get(proto, "weight"));
    _ = char_stat_set(ch, "money", mob_proto_stat_get(proto, "money"));
    _ = char_stat_set(ch, "alignment", mob_proto_stat_get(proto, "alignment"));
    _ = char_stat_set(ch, "experience", mob_proto_stat_get(proto, "experience"));
    _ = char_stat_set(ch, "powerlevel", mob_proto_stat_get(proto, "powerlevel"));
    _ = char_stat_set(ch, "ki", mob_proto_stat_get(proto, "ki"));
    _ = char_stat_set(ch, "stamina", mob_proto_stat_get(proto, "stamina"));
    _ = char_stat_set(ch, "armor", mob_proto_stat_get(proto, "armor"));
    _ = char_stat_set(ch, "level", mob_proto_stat_get(proto, "level"));
}

fn copyCharLegacyStatsToMobProto(ch: *cdb.char_data, proto: *cdb.mob_proto_data) void {
    _ = mob_proto_stat_set(proto, "strength", char_stat_get(ch, "strength"));
    _ = mob_proto_stat_set(proto, "intelligence", char_stat_get(ch, "intelligence"));
    _ = mob_proto_stat_set(proto, "wisdom", char_stat_get(ch, "wisdom"));
    _ = mob_proto_stat_set(proto, "agility", char_stat_get(ch, "agility"));
    _ = mob_proto_stat_set(proto, "constitution", char_stat_get(ch, "constitution"));
    _ = mob_proto_stat_set(proto, "speed", char_stat_get(ch, "speed"));
    _ = mob_proto_stat_set(proto, "height", char_stat_get(ch, "height"));
    _ = mob_proto_stat_set(proto, "weight", char_stat_get(ch, "weight"));
    _ = mob_proto_stat_set(proto, "money", char_stat_get(ch, "money"));
    _ = mob_proto_stat_set(proto, "alignment", char_stat_get(ch, "alignment"));
    _ = mob_proto_stat_set(proto, "experience", char_stat_get(ch, "experience"));
    _ = mob_proto_stat_set(proto, "powerlevel", char_stat_get(ch, "powerlevel"));
    _ = mob_proto_stat_set(proto, "ki", char_stat_get(ch, "ki"));
    _ = mob_proto_stat_set(proto, "stamina", char_stat_get(ch, "stamina"));
    _ = mob_proto_stat_set(proto, "armor", char_stat_get(ch, "armor"));
    _ = mob_proto_stat_set(proto, "level", char_stat_get(ch, "level"));
}

pub export fn char_id_get(ch: *cdb.char_data) i64 {
    return ch.id;
}

pub export fn char_id_set(ch: *cdb.char_data, id: i64) void {
    ch.id = @intCast(id);
}

pub export fn char_proto_id_get(ch: *cdb.char_data) cdb.mob_vnum {
    return char_vnum_get(ch);
}

pub export fn char_proto_id_set(ch: *cdb.char_data, vnum: cdb.mob_vnum) void {
    char_vnum_set(ch, vnum);
}

pub export fn char_vnum_get(ch: *cdb.char_data) cdb.mob_vnum {
    return ch.vnum;
}

pub export fn char_vnum_set(ch: *cdb.char_data, vnum: cdb.mob_vnum) void {
    ch.vnum = vnum;
}

pub export fn char_room_get(ch: *cdb.char_data) [*c]cdb.room_data {
    return cdb.room_by_id(ch.in_room);
}

pub export fn char_room_vnum_get(ch: *cdb.char_data) cdb.room_vnum {
    const room = char_room_get(ch);
    if (room == null) return cdb.NOWHERE;
    return room.*.number;
}

pub export fn char_zone_get(ch: *cdb.char_data) [*c]cdb.zone_data {
    const room = char_room_get(ch);
    if (room == null) return null;
    return cdb.room_zone_get(room);
}

pub export fn char_zone_vnum_get(ch: *cdb.char_data) cdb.zone_vnum {
    const zone = char_zone_get(ch);
    if (zone == null) return cdb.NOWHERE;
    return zone.*.number;
}

pub export fn char_room_vnum_set(ch: *cdb.char_data, vnum: cdb.room_vnum) void {
    ch.in_room = cdb.room_vnum_check(vnum);
}

pub export fn char_name_get(ch: *cdb.char_data) [*c]const u8 {
    return ch.name;
}

pub export fn char_name_set(ch: *cdb.char_data, value: ?[*:0]const u8) void {
    replaceString(&ch.name, value);
}

pub export fn char_description_get(ch: *cdb.char_data) [*c]const u8 {
    return ch.description;
}

pub export fn char_description_set(ch: *cdb.char_data, value: ?[*:0]const u8) void {
    replaceString(&ch.description, value);
}

pub export fn char_short_description_get(ch: *cdb.char_data) [*c]const u8 {
    return ch.short_descr;
}

pub export fn char_short_description_set(ch: *cdb.char_data, value: ?[*:0]const u8) void {
    replaceString(&ch.short_descr, value);
}

pub export fn char_long_description_get(ch: *cdb.char_data) [*c]const u8 {
    return ch.long_descr;
}

pub export fn char_long_description_set(ch: *cdb.char_data, value: ?[*:0]const u8) void {
    replaceString(&ch.long_descr, value);
}

pub export fn char_title_get(ch: *cdb.char_data) [*c]const u8 {
    return ch.title;
}

pub export fn char_title_set(ch: *cdb.char_data, value: ?[*:0]const u8) void {
    replaceString(&ch.title, value);
}

pub export fn char_class_get(ch: *cdb.char_data) c_int {
    return ch.chclass;
}

pub export fn char_class_set(ch: *cdb.char_data, chclass: c_int) void {
    ch.chclass = chclass;
}

pub export fn char_race_get(ch: *cdb.char_data) c_int {
    return ch.race;
}

pub export fn char_race_set(ch: *cdb.char_data, race: c_int) void {
    ch.race = race;
}

pub export fn char_size_get(ch: *cdb.char_data) c_int {
    return ch.size;
}

pub export fn char_size_set(ch: *cdb.char_data, size: c_int) void {
    ch.size = size;
}

pub export fn char_sex_get(ch: *cdb.char_data) c_int {
    return ch.sex;
}

pub export fn char_sex_set(ch: *cdb.char_data, sex: c_int) void {
    ch.sex = @intCast(sex);
}

pub export fn char_admlevel_get(ch: *cdb.char_data) c_int {
    return ch.admlevel;
}

pub export fn char_admlevel_set(ch: *cdb.char_data, admlevel: c_int) void {
    ch.admlevel = admlevel;
}

pub export fn char_admflagged(ch: *cdb.char_data, pos: c_int) bool {
    return bitflags.get(&ch.admflags, pos);
}

pub export fn char_admflag_toggle(ch: *cdb.char_data, pos: c_int) bool {
    return bitflags.toggle(&ch.admflags, pos);
}

pub export fn char_admflag_set(ch: *cdb.char_data, pos: c_int, value: bool) void {
    bitflags.set(&ch.admflags, pos, value);
}

pub export fn char_plrflagged(ch: *cdb.char_data, pos: c_int) bool {
    return bitflags.get(ch.act[0..], pos);
}

pub export fn char_plrflag_toggle(ch: *cdb.char_data, pos: c_int) bool {
    return bitflags.toggle(ch.act[0..], pos);
}

pub export fn char_plrflag_set(ch: *cdb.char_data, pos: c_int, value: bool) void {
    bitflags.set(ch.act[0..], pos, value);
}

pub export fn char_inventory_iterate(ch: *cdb.char_data, recursive: bool, func: ?obj_api.ObjIterFn, ctx: ?*anyopaque) void {
    const callback = func orelse return;
    _ = obj_api.objContentsListIterate(ch.carrying, recursive, callback, ctx);
}

pub export fn char_equipment_iterate(ch: *cdb.char_data, recursive: bool, func: ?obj_api.ObjIterFn, ctx: ?*anyopaque) void {
    const callback = func orelse return;
    for (ch.equipment) |obj| {
        if (obj == null) continue;
        if (!callback(&obj.*, ctx)) return;
        if (recursive and !obj_api.objContentsListIterate(obj.*.contains, true, callback, ctx)) return;
    }
}

pub export fn char_inventory_count(ch: *cdb.char_data, recursive: bool) usize {
    var count: usize = 0;
    var current = ch.carrying;
    while (current != null) : (current = current.*.next_content) {
        count += 1;
        if (recursive) count += obj_api.obj_inventory_count(&current.*, true);
    }
    return count;
}

pub export fn char_equipment_count(ch: *cdb.char_data, recursive: bool) usize {
    var count: usize = 0;
    for (ch.equipment) |obj| {
        if (obj == null) continue;
        count += 1;
        if (recursive) count += obj_api.obj_inventory_count(&obj.*, true);
    }
    return count;
}

pub export fn char_inventory_get(ch: *cdb.char_data, pos: usize) [*c]cdb.obj_data {
    var index: usize = 0;
    var current = ch.carrying;
    while (current != null) : (current = current.*.next_content) {
        if (index == pos) return current;
        index += 1;
    }
    return null;
}

pub export fn char_equipment_get(ch: *cdb.char_data, pos: usize) [*c]cdb.obj_data {
    if (pos >= ch.equipment.len) return null;
    return ch.equipment[pos];
}

fn replaceString(field: *[*c]u8, value: ?[*:0]const u8) void {
    const new_value = if (value) |new_string| strdup(new_string) orelse return else null;
    if (field.* != null) std.c.free(field.*);
    field.* = new_value;
}

pub export fn char_stat_get(ch: *cdb.char_data, stat: ?[*:0]const u8) i64 {
    const name = statName(stat) orelse return 0;
    return charStatGetName(ch, name);
}

fn charStatGetName(ch: *cdb.char_data, name: []const u8) i64 {
    const definition = lua_api.statDefinition(name) orelse return 0;
    const id = statId(name) orelse return 0;
    if (ch.zigdata) |ptr| {
        const zigdata: *CharacterData = @ptrCast(@alignCast(ptr));
        if (zigdata.stats.get(id)) |value| return value;
    }
    return definition.default_value;
}

pub export fn char_stat_set(ch: *cdb.char_data, stat: ?[*:0]const u8, value: i64) i64 {
    const name = statName(stat) orelse return 0;
    const definition = lua_api.statDefinition(name) orelse return 0;
    const id = statId(name) orelse return 0;
    const clamped = clampStat(value, definition);

    const zigdata = char_ensure_zigdata(ch) orelse return 0;
    zigdata.stats.set(id, clamped);
    invalidateDeriveds(zigdata);
    return clamped;
}

pub export fn char_stat_mod(ch: *cdb.char_data, stat: ?[*:0]const u8, mod: i64) i64 {
    const value = char_stat_get(ch, stat) + mod;
    return char_stat_set(ch, stat, value);
}

fn statName(stat: ?[*:0]const u8) ?[]const u8 {
    const ptr = stat orelse return null;
    const name = std.mem.span(ptr);
    if (name.len == 0) return null;
    return name;
}

fn clampStat(value: i64, definition: lua_api.StatDefinition) i64 {
    var result = value;
    if (definition.min_value) |min| result = @max(result, min);
    if (definition.max_value) |max| result = @min(result, max);
    return result;
}

pub export fn char_der_base_get(ch: *cdb.char_data, stat: ?[*:0]const u8) i64 {
    const name = statName(stat) orelse return 0;
    return charDerGetBaseName(ch, name);
}

fn charDerGetBaseName(ch: *cdb.char_data, name: []const u8) i64 {
    const definition = lua_api.derivedDefinition(name) orelse return 0;
    if (lua_api.calculateDerivedBase(ch, name)) |value| return value;
    return charStatGetName(ch, definition.baseStat(name));
}

pub export fn char_der_total_get(ch: *cdb.char_data, stat: ?[*:0]const u8) i64 {
    const name = statName(stat) orelse return 0;
    return charDerGetTotalName(ch, name);
}

fn charDerGetTotalName(ch: *cdb.char_data, name: []const u8) i64 {
    const definition = lua_api.derivedDefinition(name) orelse return 0;
    const id = derivedId(name) orelse return 0;
    const zigdata = char_ensure_zigdata(ch) orelse return 0;

    if (!zigdata.deriveds_dirty) {
        if (zigdata.deriveds.get(id)) |cached| return cached.value;
    }

    if (zigdata.modifiers.dirty) {
        zigdata.modifiers.rebuild(ch);
        emitConditionModifiers(ch, zigdata);
    }
    if (!definition.no_modifiers) addLegacyDerivedModifiers(ch, zigdata, name, definition);
    const total = calculateDerivedTotal(ch, zigdata, name, definition);
    cacheDerived(zigdata, id, total);
    return total;
}

pub export fn char_der_invalidate(ch: *cdb.char_data) void {
    const zigdata = char_ensure_zigdata(ch) orelse return;
    invalidateDeriveds(zigdata);
}

fn calculateDerivedTotal(ch: *cdb.char_data, zigdata: *CharacterData, name: []const u8, definition: lua_api.DerivedDefinition) i64 {
    var value = charDerGetBaseName(ch, name);
    var flat: i64 = 0;
    var percent: i64 = 0;
    var min_override: ?i64 = null;
    var max_override: ?i64 = null;
    var set_override: ?i64 = null;

    if (!definition.no_modifiers) {
        if (zigdata.modifiers.modifiersFor("derived", name)) |modifiers| {
            for (modifiers) |modifier| {
                switch (modifier.kind) {
                    .flat => flat += modifier.value,
                    .percent => percent += modifier.value,
                    .multiplier => {},
                    .override_min => min_override = if (min_override) |current| @max(current, modifier.value) else modifier.value,
                    .override_max => max_override = if (max_override) |current| @min(current, modifier.value) else modifier.value,
                    .set => set_override = modifier.value,
                }
            }

            value += flat;
            if (percent != 0) value += @divTrunc(value * percent, modifiers_api.scale);
            for (modifiers) |modifier| {
                if (modifier.kind == .multiplier) value = @divTrunc(value * modifier.value, modifiers_api.scale);
            }
        } else {
            value += flat;
            if (percent != 0) value += @divTrunc(value * percent, modifiers_api.scale);
        }
    }

    if (definition.min_value) |min| value = @max(value, min);
    if (definition.max_value) |max| value = @min(value, max);
    if (min_override) |min| value = @max(value, min);
    if (max_override) |max| value = @min(value, max);
    if (set_override) |set| value = set;
    return value;
}

fn addLegacyDerivedModifiers(ch: *cdb.char_data, zigdata: *CharacterData, name: []const u8, definition: lua_api.DerivedDefinition) void {
    for (definition.legacy_modifiers[0..definition.legacy_modifier_count]) |modifier| {
        modifiers_api.addLegacyDerivedFlat(&zigdata.modifiers, ch, name, modifier.location, modifier.specific);
    }
}

fn cacheDerived(zigdata: *CharacterData, id: DerivedId, value: i64) void {
    if (zigdata.deriveds_dirty) {
        clearDerivedCache(zigdata);
        zigdata.deriveds_dirty = false;
    }
    zigdata.deriveds.set(id, .{ .value = value });
}

fn invalidateDeriveds(zigdata: *CharacterData) void {
    zigdata.deriveds_dirty = true;
    zigdata.modifiers.invalidate();
}

fn conditionChanged(zigdata: *CharacterData) void {
    invalidateDeriveds(zigdata);
}

fn clearDerivedCache(zigdata: *CharacterData) void {
    zigdata.deriveds.clear();
}

pub export fn char_meter_get(ch: *cdb.char_data, meter: ?[*:0]const u8) i64 {
    const name = statName(meter) orelse return 0;
    const zigdata = char_ensure_zigdata(ch) orelse return 0;
    return zigdata.meters.get(name) orelse meter_scale;
}

pub export fn char_meter_full(ch: *cdb.char_data, meter: ?[*:0]const u8) bool {
    const name = statName(meter) orelse return false;
    const zigdata = char_ensure_zigdata(ch) orelse return false;
    if (zigdata.meters.get(name)) |value| return value >= meter_scale;
    return false;
}

pub export fn char_meter_set(ch: *cdb.char_data, meter: ?[*:0]const u8, value: i64) i64 {
    const name = statName(meter) orelse return 0;
    const clamped = clampMeter(value);

    const zigdata = char_ensure_zigdata(ch) orelse return 0;
    if (zigdata.meters.getPtr(name)) |existing| {
        existing.* = clamped;
        return clamped;
    }

    zigdata.meters.put(lua_api.internString(name), clamped) catch return 0;
    return clamped;
}

pub export fn char_meter_mod(ch: *cdb.char_data, meter: ?[*:0]const u8, mod: i64) i64 {
    const value = char_meter_get(ch, meter) + mod;
    return char_meter_set(ch, meter, value);
}

pub export fn char_meter_set_int(ch: *cdb.char_data, meter: ?[*:0]const u8, value: i64) i64 {
    const name = statName(meter) orelse return 0;
    const max = charMeterMaxName(ch, name);
    if (max <= 0) return char_meter_set(ch, meter, 0);
    return char_meter_set(ch, meter, @divTrunc(value * meter_scale, max));
}

pub export fn char_meter_mod_int(ch: *cdb.char_data, meter: ?[*:0]const u8, mod: i64) i64 {
    const name = statName(meter) orelse return 0;
    return char_meter_set_int(ch, meter, charMeterCurrentName(ch, name) + mod);
}

pub export fn char_meter_current(ch: *cdb.char_data, meter: ?[*:0]const u8) i64 {
    const name = statName(meter) orelse return 0;
    return charMeterCurrentName(ch, name);
}

pub export fn char_meter_max(ch: *cdb.char_data, meter: ?[*:0]const u8) i64 {
    const name = statName(meter) orelse return 0;
    return charMeterMaxName(ch, name);
}

fn charMeterCurrentName(ch: *cdb.char_data, name: []const u8) i64 {
    const max = charMeterMaxName(ch, name);
    if (max <= 0) return 0;
    const zigdata = char_ensure_zigdata(ch) orelse return 0;
    const current = zigdata.meters.get(name) orelse meter_scale;
    return @divTrunc(current * max, meter_scale);
}

fn charMeterMaxName(ch: *cdb.char_data, name: []const u8) i64 {
    const definition = lua_api.meterDefinition(name) orelse return 0;
    return charDerGetTotalName(ch, definition.derivedStat(name));
}

fn clampMeter(value: i64) i64 {
    return @min(@max(value, 0), meter_scale);
}

pub export fn char_skill_base_get(ch: *cdb.char_data, skill: ?[*:0]const u8) i64 {
    const index = skillIndex(skill) orelse return 0;
    return ch.skills[index].base;
}

pub export fn char_skill_base_set(ch: *cdb.char_data, skill: ?[*:0]const u8, value: i64) i64 {
    const index = skillIndex(skill) orelse return 0;
    const clamped = clampSkillByte(value);
    ch.skills[index].base = clamped;
    return clamped;
}

pub export fn char_skill_base_mod(ch: *cdb.char_data, skill: ?[*:0]const u8, mod: i64) i64 {
    const value = char_skill_base_get(ch, skill) + mod;
    return char_skill_base_set(ch, skill, value);
}

pub export fn char_skill_modifier_get(ch: *cdb.char_data, skill: ?[*:0]const u8) i64 {
    const index = skillIndex(skill) orelse return 0;
    const bonus = cdb.char_legacy_modifier(ch, cdb.APPLY_SKILL, @intCast(index));
    return bonus;
}

pub export fn char_skill_total_get(ch: *cdb.char_data, skill: ?[*:0]const u8) i64 {
    const index = skillIndex(skill) orelse return 0;
    const bonus = cdb.char_legacy_modifier(ch, cdb.APPLY_SKILL, @intCast(index));
    return @as(i64, ch.skills[index].base + bonus);
}

pub export fn char_skill_perf_get(ch: *cdb.char_data, skill: ?[*:0]const u8) i64 {
    const index = skillIndex(skill) orelse return 0;
    return ch.skills[index].perf;
}

pub export fn char_skill_perf_set(ch: *cdb.char_data, skill: ?[*:0]const u8, value: i64) i64 {
    const index = skillIndex(skill) orelse return 0;
    const clamped = clampSkillByte(value);
    ch.skills[index].perf = clamped;
    return clamped;
}

pub export fn char_skill_perf_mod(ch: *cdb.char_data, skill: ?[*:0]const u8, mod: i64) i64 {
    const value = char_skill_perf_get(ch, skill) + mod;
    return char_skill_perf_set(ch, skill, value);
}

fn skillIndex(skill: ?[*:0]const u8) ?usize {
    const name = statName(skill) orelse return null;
    var index: usize = 0;
    while (index < cdb.SKILL_TABLE_SIZE) : (index += 1) {
        const skill_name = cdb.spell_info[index].name;
        if (skill_name == null) continue;
        if (std.ascii.eqlIgnoreCase(name, std.mem.span(skill_name))) return index;
    }
    return null;
}

fn clampSkillByte(value: i64) i8 {
    return std.math.cast(i8, @min(@max(value, std.math.minInt(i8)), std.math.maxInt(i8))).?;
}

pub export fn char_condition_has(ch: *cdb.char_data, condition: ?[*:0]const u8) bool {
    const name = statName(condition) orelse return false;
    if (ch.zigdata == null) return false;
    const zigdata: *CharacterData = @ptrCast(@alignCast(ch.zigdata.?));
    return zigdata.conditions.contains(name);
}

pub export fn char_condition_id_has_tag(condition: ?[*:0]const u8, tag: ?[*:0]const u8) bool {
    const condition_name = statName(condition) orelse return false;
    const tag_name = statName(tag) orelse return false;
    return lua_api.conditionHasTag(condition_name, tag_name);
}

pub export fn char_condition_has_tag(ch: *cdb.char_data, tag: ?[*:0]const u8) bool {
    return char_condition_active_with_tag(ch, tag) != null;
}

pub export fn char_condition_active_with_tag(ch: *cdb.char_data, tag: ?[*:0]const u8) [*c]const u8 {
    const tag_name = statName(tag) orelse return null;
    if (ch.zigdata == null) return null;
    const zigdata: *CharacterData = @ptrCast(@alignCast(ch.zigdata.?));
    var it = zigdata.conditions.keyIterator();
    while (it.next()) |key| {
        if (lua_api.conditionHasTag(key.*, tag_name)) return @ptrCast(key.*.ptr);
    }
    return null;
}

pub export fn char_condition_add(ch: *cdb.char_data, condition: ?[*:0]const u8, source_category: ?[*:0]const u8, source_id: ?[*:0]const u8) bool {
    return char_condition_add_with_variables(ch, condition, source_category, source_id, null, 0, null, 0);
}

pub export fn char_condition_add_with_variables(ch: *cdb.char_data, condition: ?[*:0]const u8, source_category: ?[*:0]const u8, source_id: ?[*:0]const u8, numbers: ?[*]const ConditionNumberArg, number_count: usize, strings: ?[*]const ConditionStringArg, string_count: usize) bool {
    const name = statName(condition) orelse return false;
    const definition = lua_api.conditionDefinition(name) orelse return false;
    const zigdata = char_ensure_zigdata(ch) orelse return false;
    const is_new = !zigdata.conditions.contains(name);

    if (is_new) {
        const key = lua_api.internString(name);
        var instance = ConditionInstance.init(std.heap.page_allocator, name) catch {
            return false;
        };
        zigdata.conditions.put(key, instance) catch {
            instance.deinit(std.heap.page_allocator);
            return false;
        };
    } else if (definition.stackable) {
        zigdata.conditions.getPtr(name).?.stacks += 1;
    }

    if (zigdata.conditions.getPtr(name)) |instance| {
        addConditionVariables(instance, numbers, number_count, strings, string_count) catch return false;
        addConditionSource(instance, source_category, source_id) catch {};
    }
    conditionChanged(zigdata);
    lua_api.callConditionHook(ch, name, "on_apply");
    return true;
}

pub export fn char_condition_apply(ch: *cdb.char_data, condition: ?[*:0]const u8, source_category: ?[*:0]const u8, source_id: ?[*:0]const u8) bool {
    return char_condition_apply_with_variables(ch, condition, source_category, source_id, null, 0, null, 0);
}

pub export fn char_condition_apply_with_variables(ch: *cdb.char_data, condition: ?[*:0]const u8, source_category: ?[*:0]const u8, source_id: ?[*:0]const u8, numbers: ?[*]const ConditionNumberArg, number_count: usize, strings: ?[*]const ConditionStringArg, string_count: usize) bool {
    const name = statName(condition) orelse return false;
    if (lua_api.conditionDefinition(name) == null) return false;
    if (ch.zigdata) |ptr| {
        const zigdata: *CharacterData = @ptrCast(@alignCast(ptr));
        var to_remove = std.array_list.Managed([:0]u8).init(std.heap.page_allocator);
        defer {
            for (to_remove.items) |item| std.heap.page_allocator.free(item);
            to_remove.deinit();
        }

        var it = zigdata.conditions.keyIterator();
        while (it.next()) |key| {
            if (std.mem.eql(u8, key.*, name)) continue;
            if (!lua_api.conditionsConflict(name, key.*)) continue;
            to_remove.append(std.heap.page_allocator.dupeZ(u8, key.*) catch return false) catch return false;
        }

        for (to_remove.items) |item| _ = char_condition_remove(ch, item.ptr, "exclusive");
    }
    return char_condition_add_with_variables(ch, condition, source_category, source_id, numbers, number_count, strings, string_count);
}

pub export fn char_condition_apply_with_number(ch: *cdb.char_data, condition: ?[*:0]const u8, source_category: ?[*:0]const u8, source_id: ?[*:0]const u8, key: ?[*:0]const u8, value: i64) bool {
    const args = [_]ConditionNumberArg{.{ .key = key, .value = value }};
    return char_condition_apply_with_variables(ch, condition, source_category, source_id, &args, args.len, null, 0);
}

pub export fn char_condition_apply_with_numbers2(ch: *cdb.char_data, condition: ?[*:0]const u8, source_category: ?[*:0]const u8, source_id: ?[*:0]const u8, key1: ?[*:0]const u8, value1: i64, key2: ?[*:0]const u8, value2: i64) bool {
    const args = [_]ConditionNumberArg{ .{ .key = key1, .value = value1 }, .{ .key = key2, .value = value2 } };
    return char_condition_apply_with_variables(ch, condition, source_category, source_id, &args, args.len, null, 0);
}

pub export fn char_condition_remove(ch: *cdb.char_data, condition: ?[*:0]const u8, reason: ?[*:0]const u8) bool {
    _ = reason;
    const name = statName(condition) orelse return false;
    if (ch.zigdata == null) return false;
    const zigdata: *CharacterData = @ptrCast(@alignCast(ch.zigdata.?));
    var removed = zigdata.conditions.fetchRemove(name) orelse return false;
    removed.value.deinit(std.heap.page_allocator);
    conditionChanged(zigdata);
    lua_api.callConditionHook(ch, name, "on_remove");
    return true;
}

pub export fn char_condition_remove_tag(ch: *cdb.char_data, tag: ?[*:0]const u8, reason: ?[*:0]const u8) c_int {
    const tag_name = statName(tag) orelse return 0;
    if (ch.zigdata == null) return 0;
    const zigdata: *CharacterData = @ptrCast(@alignCast(ch.zigdata.?));
    var to_remove = std.array_list.Managed([:0]u8).init(std.heap.page_allocator);
    defer {
        for (to_remove.items) |item| std.heap.page_allocator.free(item);
        to_remove.deinit();
    }

    var it = zigdata.conditions.keyIterator();
    while (it.next()) |key| {
        if (!lua_api.conditionHasTag(key.*, tag_name)) continue;
        to_remove.append(std.heap.page_allocator.dupeZ(u8, key.*) catch return 0) catch return 0;
    }

    var removed: c_int = 0;
    for (to_remove.items) |item| {
        if (char_condition_remove(ch, item.ptr, reason)) removed += 1;
    }
    return removed;
}

pub export fn char_condition_update(ch: *cdb.char_data) void {
    char_condition_update_context(ch, "manual", 0, 0);
}

pub export fn char_condition_update_with_context(ch: *cdb.char_data, kind: ?[*:0]const u8, pulses: i64, seconds: i64) void {
    char_condition_update_context(ch, statName(kind) orelse "manual", pulses, seconds);
}

pub export fn char_condition_update_all(kind: ?[*:0]const u8, pulses: i64, seconds: i64) void {
    const update_kind = statName(kind) orelse "manual";
    const iterator = characters.char_iterator_create() orelse return;
    defer characters.char_iterator_free(iterator);

    var ids = std.array_list.Managed(i64).init(std.heap.page_allocator);
    defer ids.deinit();

    while (characters.char_next(iterator)) |ch| {
        if (cdb.char_is_extracted(ch)) continue;
        ids.append(cdb.char_id_get(ch)) catch return;
    }

    for (ids.items) |id| {
        const ch = characters.char_by_id(id) orelse continue;
        if (cdb.char_is_extracted(ch)) continue;
        char_condition_update_context(ch, update_kind, pulses, seconds);
    }
}

fn char_condition_update_context(ch: *cdb.char_data, kind: []const u8, pulses: i64, seconds: i64) void {
    if (ch.zigdata == null) return;
    const zigdata: *CharacterData = @ptrCast(@alignCast(ch.zigdata.?));

    var names = std.array_list.Managed([:0]u8).init(std.heap.page_allocator);
    defer {
        for (names.items) |name| std.heap.page_allocator.free(name);
        names.deinit();
    }

    var it = zigdata.conditions.keyIterator();
    while (it.next()) |key| names.append(std.heap.page_allocator.dupeZ(u8, key.*) catch return) catch return;

    for (names.items) |name| {
        const instance = conditionGet(ch, name.ptr) orelse continue;
        if (instance.duration == 0) {
            _ = char_condition_remove(ch, name.ptr, "expired");
            continue;
        }

        lua_api.callConditionUpdateHook(ch, name, kind, pulses, seconds);
        const updated = conditionGet(ch, name.ptr) orelse continue;
        if (seconds > 0 and updated.duration > 0) {
            updated.duration = @max(0, updated.duration - seconds);
            conditionChanged(@ptrCast(@alignCast(ch.zigdata.?)));
        }
        const after_duration = conditionGet(ch, name.ptr) orelse continue;
        if (after_duration.duration == 0) _ = char_condition_remove(ch, name.ptr, "expired");
    }
}

pub export fn char_condition_stacks_get(ch: *cdb.char_data, condition: ?[*:0]const u8) i64 {
    const instance = conditionGet(ch, condition) orelse return 0;
    return instance.stacks;
}

pub export fn char_condition_stacks_set(ch: *cdb.char_data, condition: ?[*:0]const u8, value: i64) i64 {
    const instance = conditionGet(ch, condition) orelse return 0;
    instance.stacks = @max(0, value);
    conditionChanged(@ptrCast(@alignCast(ch.zigdata.?)));
    return instance.stacks;
}

pub export fn char_condition_duration_get(ch: *cdb.char_data, condition: ?[*:0]const u8) i64 {
    const instance = conditionGet(ch, condition) orelse return 0;
    return instance.duration;
}

pub export fn char_condition_duration_set(ch: *cdb.char_data, condition: ?[*:0]const u8, value: i64) i64 {
    const instance = conditionGet(ch, condition) orelse return 0;
    instance.duration = value;
    conditionChanged(@ptrCast(@alignCast(ch.zigdata.?)));
    return value;
}

pub export fn char_condition_number_get(ch: *cdb.char_data, condition: ?[*:0]const u8, key: ?[*:0]const u8) i64 {
    const instance = conditionGet(ch, condition) orelse return 0;
    const name = statName(key) orelse return 0;
    return instance.numbers.get(name) orelse 0;
}

pub export fn char_condition_number_set(ch: *cdb.char_data, condition: ?[*:0]const u8, key: ?[*:0]const u8, value: i64) i64 {
    const instance = conditionGet(ch, condition) orelse return 0;
    const name = statName(key) orelse return 0;
    putOwnedNumber(instance, name, value) catch return 0;
    conditionChanged(@ptrCast(@alignCast(ch.zigdata.?)));
    return value;
}

pub export fn char_condition_number_mod(ch: *cdb.char_data, condition: ?[*:0]const u8, key: ?[*:0]const u8, mod: i64) i64 {
    const value = char_condition_number_get(ch, condition, key) + mod;
    return char_condition_number_set(ch, condition, key, value);
}

pub export fn char_condition_string_get(ch: *cdb.char_data, condition: ?[*:0]const u8, key: ?[*:0]const u8) [*c]const u8 {
    const instance = conditionGet(ch, condition) orelse return null;
    const name = statName(key) orelse return null;
    const value = instance.strings.get(name) orelse return null;
    return @ptrCast(value.ptr);
}

pub export fn char_condition_string_set(ch: *cdb.char_data, condition: ?[*:0]const u8, key: ?[*:0]const u8, value: ?[*:0]const u8) bool {
    const instance = conditionGet(ch, condition) orelse return false;
    const name = statName(key) orelse return false;
    const text = statName(value) orelse return false;
    putOwnedString(instance, name, text) catch return false;
    conditionChanged(@ptrCast(@alignCast(ch.zigdata.?)));
    return true;
}

pub export fn char_transform_has(ch: *cdb.char_data, transform: ?[*:0]const u8) bool {
    const name = statName(transform) orelse return false;
    if (ch.zigdata == null) return false;
    const zigdata: *CharacterData = @ptrCast(@alignCast(ch.zigdata.?));
    return zigdata.transforms.contains(name);
}

pub export fn char_transform_add(ch: *cdb.char_data, transform: ?[*:0]const u8) bool {
    const name = statName(transform) orelse return false;
    const zigdata = char_ensure_zigdata(ch) orelse return false;
    if (zigdata.transforms.contains(name)) return true;

    const key = lua_api.internString(name);
    var data = TransformData.init(std.heap.page_allocator, name) catch {
        return false;
    };
    zigdata.transforms.put(key, data) catch {
        data.deinit(std.heap.page_allocator);
        return false;
    };
    return true;
}

pub export fn char_transform_remove(ch: *cdb.char_data, transform: ?[*:0]const u8) bool {
    const name = statName(transform) orelse return false;
    if (ch.zigdata == null) return false;
    const zigdata: *CharacterData = @ptrCast(@alignCast(ch.zigdata.?));
    var removed = zigdata.transforms.fetchRemove(name) orelse return false;
    removed.value.deinit(std.heap.page_allocator);
    return true;
}

pub export fn char_transform_unlocked(ch: *cdb.char_data, transform: ?[*:0]const u8) bool {
    return char_transform_number_get(ch, transform, "unlocked") != 0;
}

pub export fn char_transform_unlock(ch: *cdb.char_data, transform: ?[*:0]const u8, source: ?[*:0]const u8) bool {
    _ = statName(transform) orelse return false;
    if (!char_transform_add(ch, transform)) return false;
    _ = char_transform_number_set(ch, transform, "unlocked", 1);
    if (statName(source)) |source_text| {
        if (source_text.len > 0) _ = char_transform_string_set(ch, transform, "unlock_source", source);
    }
    return true;
}

pub export fn char_transform_number_get(ch: *cdb.char_data, transform: ?[*:0]const u8, key: ?[*:0]const u8) i64 {
    const data = transformGet(ch, transform) orelse return 0;
    const name = statName(key) orelse return 0;
    return data.numbers.get(name) orelse 0;
}

pub export fn char_transform_number_set(ch: *cdb.char_data, transform: ?[*:0]const u8, key: ?[*:0]const u8, value: i64) i64 {
    if (!char_transform_add(ch, transform)) return 0;
    const data = transformGet(ch, transform) orelse return 0;
    const name = statName(key) orelse return 0;
    putOwnedTransformNumber(data, name, value) catch return 0;
    return value;
}

pub export fn char_transform_number_mod(ch: *cdb.char_data, transform: ?[*:0]const u8, key: ?[*:0]const u8, mod: i64) i64 {
    const value = char_transform_number_get(ch, transform, key) + mod;
    return char_transform_number_set(ch, transform, key, value);
}

pub export fn char_transform_string_get(ch: *cdb.char_data, transform: ?[*:0]const u8, key: ?[*:0]const u8) [*c]const u8 {
    const data = transformGet(ch, transform) orelse return null;
    const name = statName(key) orelse return null;
    const value = data.strings.get(name) orelse return null;
    return @ptrCast(value.ptr);
}

pub export fn char_transform_string_set(ch: *cdb.char_data, transform: ?[*:0]const u8, key: ?[*:0]const u8, value: ?[*:0]const u8) bool {
    if (!char_transform_add(ch, transform)) return false;
    const data = transformGet(ch, transform) orelse return false;
    const name = statName(key) orelse return false;
    const text = statName(value) orelse return false;
    putOwnedTransformString(data, name, text) catch return false;
    return true;
}

fn conditionGet(ch: *cdb.char_data, condition: ?[*:0]const u8) ?*ConditionInstance {
    const name = statName(condition) orelse return null;
    if (ch.zigdata == null) return null;
    const zigdata: *CharacterData = @ptrCast(@alignCast(ch.zigdata.?));
    return zigdata.conditions.getPtr(name);
}

fn transformGet(ch: *cdb.char_data, transform: ?[*:0]const u8) ?*TransformData {
    const name = statName(transform) orelse return null;
    if (ch.zigdata == null) return null;
    const zigdata: *CharacterData = @ptrCast(@alignCast(ch.zigdata.?));
    return zigdata.transforms.getPtr(name);
}

fn addConditionSource(instance: *ConditionInstance, source_category: ?[*:0]const u8, source_id: ?[*:0]const u8) !void {
    const category = if (source_category) |ptr| std.mem.span(ptr) else "unknown";
    const id = if (source_id) |ptr| std.mem.span(ptr) else "unknown";
    try instance.sources.append(.{
        .category = try std.heap.page_allocator.dupe(u8, category),
        .id = try std.heap.page_allocator.dupe(u8, id),
    });
}

fn addConditionVariables(instance: *ConditionInstance, numbers: ?[*]const ConditionNumberArg, number_count: usize, strings: ?[*]const ConditionStringArg, string_count: usize) !void {
    if (numbers) |items| {
        for (items[0..number_count]) |item| {
            const key = statName(item.key) orelse continue;
            try putOwnedNumber(instance, key, item.value);
        }
    }
    if (strings) |items| {
        for (items[0..string_count]) |item| {
            const key = statName(item.key) orelse continue;
            const value = statName(item.value) orelse continue;
            try putOwnedString(instance, key, value);
        }
    }
}

fn putOwnedNumber(instance: *ConditionInstance, key: []const u8, value: i64) !void {
    if (instance.numbers.getPtr(key)) |existing| {
        existing.* = value;
        return;
    }
    try instance.numbers.put(lua_api.internString(key), value);
}

fn putOwnedString(instance: *ConditionInstance, key: []const u8, value: []const u8) !void {
    if (instance.strings.getPtr(key)) |existing| {
        std.heap.page_allocator.free(existing.*);
        existing.* = try std.heap.page_allocator.dupeZ(u8, value);
        return;
    }
    try instance.strings.put(lua_api.internString(key), try std.heap.page_allocator.dupeZ(u8, value));
}

fn putOwnedTransformNumber(data: *TransformData, key: []const u8, value: i64) !void {
    if (data.numbers.getPtr(key)) |existing| {
        existing.* = value;
        return;
    }
    try data.numbers.put(lua_api.internString(key), value);
}

fn putOwnedTransformString(data: *TransformData, key: []const u8, value: []const u8) !void {
    if (data.strings.getPtr(key)) |existing| {
        std.heap.page_allocator.free(existing.*);
        existing.* = try std.heap.page_allocator.dupeZ(u8, value);
        return;
    }
    try data.strings.put(lua_api.internString(key), try std.heap.page_allocator.dupeZ(u8, value));
}

fn emitConditionModifiers(ch: *cdb.char_data, zigdata: *CharacterData) void {
    lua_api.emitRaceModifiers(ch, &zigdata.modifiers, ch.race);
    var it = zigdata.conditions.iterator();
    while (it.next()) |entry| lua_api.emitConditionModifiers(ch, &zigdata.modifiers, entry.key_ptr.*);
}

pub export fn char_is_npc(ch: *cdb.char_data) bool {
    return cdb.flag_test(@ptrCast(&ch.act), cdb.MOB_ISNPC) != 0;
}

pub export fn char_next_in_room_get(ch: *cdb.char_data) [*c]cdb.char_data {
    return ch.next_in_room;
}

pub export fn char_carrying_get(ch: *cdb.char_data) [*c]cdb.obj_data {
    return ch.carrying;
}
