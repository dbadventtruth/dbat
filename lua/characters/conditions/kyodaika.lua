return {
    id = "kyodaika",
    name = "@GKyodaika@n",
    tags = { "kyodaika" },
    persistent = true,
    modifiers = function(ch)
        return {
            { target = { "derived", "strength" }, kind = "flat", value = 5, label = "Kyodaika" },
            { target = { "derived", "speed" }, kind = "flat", value = -2, label = "Kyodaika" },
            { target = { "derived", "height" }, kind = "multiplier", value = 100000, label = "Kyodaika" },
            { target = { "derived", "weight" }, kind = "multiplier", value = 500000, label = "Kyodaika" },
        }
    end,
    status_line = function(ch, cond) return "You have used kyodaika." end,
}
