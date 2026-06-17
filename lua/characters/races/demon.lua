return {
    id = "demon",
    legacy_id = 10,
    name = "Demon",
    abbreviation = "Dem",
    size = "medium",
    pc_ok = true,
    modifiers = function()
        return {
            { target = { "derived", "lifeforce" }, kind = "multiplier", value = 7500, label = "Demon" },
        }
    end,
}
