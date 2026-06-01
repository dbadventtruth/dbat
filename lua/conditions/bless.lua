local function level(ch, condition)
    local value = condition:number_get("level")
    if value <= 0 then value = ch:condition_number_get("bless", "level") end
    if value < 0 then return 0 end
    if value > 100 then return 100 end
    return value
end

return {
    id = "bless",
    name = "Bless",
    tags = { "blessing", "lifeforce_bonus" },
    persistent = false,
    modifiers = function(ch, condition)
        local bonus = level(ch, condition) * 10 -- 100 skill/level = +10%.
        if bonus <= 0 then return {} end
        return {
            { target = { "derived", "lifeforce" }, kind = "percent", value = bonus, label = "Bless" },
        }
    end,
}
