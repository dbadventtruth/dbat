local function level(ch, condition)
    local value = condition:number_get("level")
    if value <= 0 then value = ch:stat_get("kaioken") end
    if value < 0 then return 0 end
    return value
end

return {
    id = "kaioken",
    name = "Kaioken",
    tags = { "power_amp", "kaioken" },
    persistent = false,
    modifiers = function(ch, condition)
        local bonus = level(ch, condition) * 1000 -- +10% per Kaioken level.
        if bonus <= 0 then return {} end
        return {
            { target = { "derived", "powerlevel" }, kind = "percent", value = bonus, label = "Kaioken" },
        }
    end,
}
