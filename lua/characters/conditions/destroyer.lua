return {
    id = "destroyer",
    name = "Destroyer",
    tags = { "destroyer" },
    persistent = true,
    modifiers = function(ch)
        local room = ch:room_get()
        if room and room:damage_get() >= 75 then
            return {
                { target = { "regen", "vitals" }, kind = "percent", value = 5000, label = "Destroyer" },
            }
        end
        return {}
    end,
}