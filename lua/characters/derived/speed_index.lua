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
        local race = ch:race_get()
        local sv   = speed_var(ch)
        local spd  = ch:der_total("speed")

        local speedcalc
        if ch:condition_has("grappling") or ch:condition_has("grappled") then
            speedcalc = spd
        elseif (race == "konatsu" or race == "demon") and ch:condition_has("flying") then
            speedcalc = sv * 125 // 100
        else
            speedcalc = sv
        end

        local speedbonus = 0
        if race == "arlian" then
            if ch:condition_has("arlian_shell") then
                speedbonus = sv * -50 // 100
            elseif ch:sex_get() == "male" and ch:condition_has("flying") then
                speedbonus = sv * 50 // 100
            end
        end

        local speedboost = 0
        if ch:condition_has("hayasa") then
            speedboost = speedcalc * 50 // 100
        end

        local sub_total = speedcalc + speedbonus + speedboost
        local mutboost = 0
        if race == "mutant" and ch:condition_has("mutation_extreme_speed") then
            mutboost = sub_total * 30 // 100
        end

        return sub_total + mutboost
    end,
}
