return {
    id = "arlian",
    legacy_id = 20,
    name = "Arlian",
    abbreviation = "Arl",
    size = "medium",
    pc_ok = true,
    modifiers = function(ch)
        local molt_level = ch:stat_get("molt_level")
        if molt_level <= 0 then return {} end
        return {
            { target = { "derived", "lifeforce" }, kind = "percent", value = molt_level * 2, label = "Arlian Molt" },
        }
    end,
}
