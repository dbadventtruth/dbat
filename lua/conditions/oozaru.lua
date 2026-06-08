return {
    id = "oozaru",
    name = "@ROozaru@n",
    family = "oozaru",
    tags = { "transformation", "oozaru" },
    exclusive_tags = { "transformation" },
    bonus = 10000,
    mult = 2.0,
    drain = 0.0,
    requires_pl = 0,
    modifiers = function(ch)
        return {
            { target = { "derived", "height" }, kind = "multiplier", value = 100000, label = "Oozaru" },
            { target = { "derived", "weight" }, kind = "multiplier", value = 500000, label = "Oozaru" },
        }
    end,
}
