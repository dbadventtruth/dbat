return {
    id = "konatsu",
    legacy_id = 3,
    name = "Konatsu",
    abbreviation = "kon",
    size = "medium",
    pc_ok = true,
    modifiers = function()
        return {
            { target = { "derived", "lifeforce" }, kind = "multiplier", value = 8500, label = "Konatsu" },
            { target = { "derived", "ki_regen" }, kind = "multiplier", value = -2000, label = "Konatsu" },
        }
    end,
}
