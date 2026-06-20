return {
    id         = "bonus_destroyer",
    name       = "Destroyer",
    tags       = { "bonus" },
    persistent = false,
    modifiers = function(ch)
        local room = ch:room_get()
        if room and room:damage_get() >= 75 then
            return {
                { target = { "regen", "vitals" }, kind = "percent", value = 5000, label = "Destroyer" },
            }
        end
        return {}
    end,
    description = "Destroyer - Damaged Rooms act as regen rooms for you",
}
