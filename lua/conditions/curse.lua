return {
    id = "curse",
    name = "Curse",
    tags = { "curse", "affliction" },
    persistent = false,
    modifiers = function()
        return {
            { target = { "regen", "vitals" }, kind = "multiplier", value = -8000, label = "Curse" },
        }
    end,
}
