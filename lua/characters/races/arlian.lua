return {
    id = "arlian",
    legacy_id = 20,
    name = "Arlian",
    abbreviation = "Arl",
    size = "medium",
    pc_ok = true,
    modifiers = function(ch)
        local molt_level = ch:stat_get("molt_level")
        local mods = {}
        mods[#mods + 1] = { target = { "derived", "lifeforce" }, kind = "percent", value = molt_level * 2, label = "Arlian Molt" }

        mods[#mods + 1] = { target = { "derived", "stamina_regen" }, kind = "percent", value = 10000, label = "Arlian" }
        mods[#mods + 1] = { target = {"derived", "powerlevel_regen"}, kind = "percent", value = -5000, label = "Arlian" }
        mods[#mods + 1] = { target = { "derived", "ki_regen" }, kind = "percent", value = -7000, label = "Arlian" }

        if ch:sex_get() == "female" and ch:is_outside() then
            mods[#mods + 1] = { target = { "derived", "stamina_regen" }, kind = "percent", value = 2000, label = "Arlian Female"}
            mods[#mods + 1] = { target = { "derived", "ki_regen" }, kind = "percent", value = 40000, label = "Arlian Female"}
        end

        return mods
    end,
}
