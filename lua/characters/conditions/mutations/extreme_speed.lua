return {
    id         = "mutation_extreme_speed",
    name       = "Extreme Speed",
    tags       = { "mutation" },
    persistent = false,
    modifiers  = function(ch, cond)
        return {
            { target = { "derived", "speed_index" }, kind = "multiplier", value = 13000, label = "Extreme Speed" },
        }
    end,
}
