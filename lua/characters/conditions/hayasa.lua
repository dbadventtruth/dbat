return {
    id         = "hayasa",
    name       = "Hayasa",
    tags       = { "hayasa", "speed_boost" },
    persistent = false,
    modifiers  = function(ch, cond)
        return {
            { target = { "derived", "speed_index" }, kind = "percent", value = 5000, label = "Hayasa" },
        }
    end,
}
