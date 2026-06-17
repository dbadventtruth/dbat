local scale = 1000000

local function speed_int(ch)
    local spd    = ch:der_total("speed")
    local agi    = ch:der_total("agility")
    local max_pl = ch:meter_max("lifeforce")
    local kaio   = ch:stat_get("kaioken")
    if ch:race_get() == "bio" then
        return (spd * agi) * (max_pl // 1200) // 1200 + spd * kaio * 100
    else
        return (spd * agi) * (max_pl // 1000) // 1000 + spd * kaio * 100
    end
end

local function speed_var(ch)
    local si     = speed_int(ch)
    local burden = ch:der_total("burden")
    local vem    = si * (scale - burden) // scale
    return math.max(vem, ch:der_total("speed"))
end

return {
    id        = "speed_index",
    name      = "Speed Index",
    min_value = 0,
    calculate_base = function(ch)
        if ch:condition_has("grappling") or ch:condition_has("grappled") then
            return ch:der_total("speed")
        end
        return speed_var(ch)
    end,
}
