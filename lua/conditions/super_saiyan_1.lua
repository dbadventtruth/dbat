local RACE_SAIYAN = 1
local RACE_HALFBREED = 7
local PLR_LSSJ = 68

local function data(ch)
    local race = ch:race_get()
    if race == RACE_HALFBREED then
        return { bonus = 900000, mult = 20000, name = "@YSuper @CSaiyan @WFirst@n" }
    end
    if race == RACE_SAIYAN then
        if ch:player_flagged(PLR_LSSJ) then
            return { bonus = 800000, mult = 20000, name = "@YSuper @CSaiyan @WFirst@n" }
        end
        return { bonus = 800000, mult = 20000, name = "@YSuper @CSaiyan @WFirst@n" }
    end
    return nil
end

local function modifiers(ch)
    local form = data(ch)
    if form == nil then return {} end
    return {
        { target = { "derived", "powerlevel" }, kind = "flat", value = form.bonus, label = form.name },
        { target = { "derived", "ki" }, kind = "flat", value = form.bonus, label = form.name },
        { target = { "derived", "stamina" }, kind = "flat", value = form.bonus, label = form.name },
        { target = { "derived", "powerlevel" }, kind = "multiplier", value = form.mult, label = form.name },
        { target = { "derived", "ki" }, kind = "multiplier", value = form.mult, label = form.name },
        { target = { "derived", "stamina" }, kind = "multiplier", value = form.mult, label = form.name },
    }
end

return {
    id = "super_saiyan_1",
    name = "Super Saiyan First",
    tags = { "transformation", "super_saiyan" },
    exclusive_tags = { "transformation" },
    persistent = true,
    modifiers = modifiers,
}
