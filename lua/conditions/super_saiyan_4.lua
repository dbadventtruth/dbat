local RACE_SAIYAN = 1
local PLR_LSSJ = 68

local function data(ch)
    if ch:race_get() ~= RACE_SAIYAN or ch:player_flagged(PLR_LSSJ) then return nil end
    return { bonus = 200000000, mult = 50000, name = "@YSuper @CSaiyan @WFourth@n" }
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
    id = "super_saiyan_4",
    name = "Super Saiyan Fourth",
    tags = { "transformation", "super_saiyan" },
    exclusive_tags = { "transformation" },
    persistent = true,
    modifiers = modifiers,
}
