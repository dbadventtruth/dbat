const std = @import("std");
const ct = @import("consts_table.zig");
const zlua = @import("zlua");
const Lua = zlua.Lua;

fn pushConstTable(lua: *Lua, comptime entries: anytype) void {
    lua.newTable();
    inline for (std.meta.fields(@TypeOf(entries))) |field| {
        lua.pushInteger(@intCast(@field(entries, field.name)));
        lua.setField(-2, field.name);
    }
}

pub fn register(lua: *Lua) void {
    lua.newTable(); // becomes dbat.consts

    pushConstTable(lua, ct.prf_flags);       lua.setField(-2, "prf_flags");
    pushConstTable(lua, ct.player_flags);    lua.setField(-2, "player_flags");
    pushConstTable(lua, ct.admin_flags);     lua.setField(-2, "admin_flags");
    pushConstTable(lua, ct.adm_levels);      lua.setField(-2, "adm_levels");
    pushConstTable(lua, ct.mob_flags);       lua.setField(-2, "mob_flags");
    pushConstTable(lua, ct.aff_flags);       lua.setField(-2, "aff_flags");
    pushConstTable(lua, ct.room_flags);      lua.setField(-2, "room_flags");
    pushConstTable(lua, ct.zone_flags);      lua.setField(-2, "zone_flags");
    pushConstTable(lua, ct.positions);       lua.setField(-2, "positions");
    pushConstTable(lua, ct.races);           lua.setField(-2, "races");
    pushConstTable(lua, ct.sexes);           lua.setField(-2, "sexes");
    pushConstTable(lua, ct.con_states);      lua.setField(-2, "con_states");
    pushConstTable(lua, ct.applies);         lua.setField(-2, "applies");
    pushConstTable(lua, ct.sizes);           lua.setField(-2, "sizes");
    pushConstTable(lua, ct.aligns);          lua.setField(-2, "aligns");
    pushConstTable(lua, ct.bonuses);         lua.setField(-2, "bonuses");
    pushConstTable(lua, ct.color_choices);   lua.setField(-2, "color_choices");
    pushConstTable(lua, ct.death_types);     lua.setField(-2, "death_types");
    pushConstTable(lua, ct.fish_states);     lua.setField(-2, "fish_states");
    pushConstTable(lua, ct.fight_prefs);     lua.setField(-2, "fight_prefs");
    pushConstTable(lua, ct.history_types);   lua.setField(-2, "history_types");
    pushConstTable(lua, ct.ocarina_songs);   lua.setField(-2, "ocarina_songs");
    pushConstTable(lua, ct.attack_types);    lua.setField(-2, "attack_types");
    pushConstTable(lua, ct.sector_types);    lua.setField(-2, "sector_types");
    pushConstTable(lua, ct.assembly_types);  lua.setField(-2, "assembly_types");
    pushConstTable(lua, ct.auction_states);  lua.setField(-2, "auction_states");
    pushConstTable(lua, ct.wield_types);     lua.setField(-2, "wield_types");
    pushConstTable(lua, ct.crit_types);      lua.setField(-2, "crit_types");
    pushConstTable(lua, ct.liquid_types);    lua.setField(-2, "liquid_types");
    pushConstTable(lua, ct.materials);       lua.setField(-2, "materials");
    pushConstTable(lua, ct.spell_levels);    lua.setField(-2, "spell_levels");
    pushConstTable(lua, ct.magic_domains);   lua.setField(-2, "magic_domains");
    pushConstTable(lua, ct.magic_schools);   lua.setField(-2, "magic_schools");
    pushConstTable(lua, ct.classes);         lua.setField(-2, "classes");
    pushConstTable(lua, ct.senseis);         lua.setField(-2, "senseis");
    pushConstTable(lua, ct.skills);          lua.setField(-2, "skills");
    pushConstTable(lua, ct.mob_trig_types);  lua.setField(-2, "mob_trig_types");
    pushConstTable(lua, ct.obj_trig_types);  lua.setField(-2, "obj_trig_types");
    pushConstTable(lua, ct.wld_trig_types);  lua.setField(-2, "wld_trig_types");
    pushConstTable(lua, ct.obj_cmd_types);   lua.setField(-2, "obj_cmd_types");
    pushConstTable(lua, ct.trig_states);     lua.setField(-2, "trig_states");
    pushConstTable(lua, ct.wear_positions);  lua.setField(-2, "wear_positions");
    pushConstTable(lua, ct.item_wear_flags); lua.setField(-2, "item_wear_flags");
    pushConstTable(lua, ct.item_types);      lua.setField(-2, "item_types");
    pushConstTable(lua, ct.item_extra_flags); lua.setField(-2, "item_extra_flags");
    pushConstTable(lua, ct.container_flags); lua.setField(-2, "container_flags");
    pushConstTable(lua, ct.distfea);         lua.setField(-2, "distfea");
    pushConstTable(lua, ct.aura_colors);     lua.setField(-2, "aura_colors");
    pushConstTable(lua, ct.eye_colors);      lua.setField(-2, "eye_colors");
    pushConstTable(lua, ct.hair_length);     lua.setField(-2, "hair_length");
    pushConstTable(lua, ct.hair_color);      lua.setField(-2, "hair_color");
    pushConstTable(lua, ct.hair_style);      lua.setField(-2, "hair_style");
    pushConstTable(lua, ct.skin_colors);     lua.setField(-2, "skin_colors");
    pushConstTable(lua, ct.annual_phases);   lua.setField(-2, "annual_phases");
    pushConstTable(lua, ct.directions);      lua.setField(-2, "directions");
    pushConstTable(lua, ct.player_conds);    lua.setField(-2, "player_conds");

    lua.setField(-2, "consts");
}
