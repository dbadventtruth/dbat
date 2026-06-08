return {
    id = "poison",
    name = "Poison",
    tags = { "poison", "affliction" },
    persistent = false,
    modifiers = function()
        return {
            { target = { "regen", "vitals" }, kind = "multiplier", value = -7500, label = "Poison" },
        }
    end,
}
