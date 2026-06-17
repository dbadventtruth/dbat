local function data(ch)
    return { bonus = 240000000, mult = 50000, name = "@cPotential @CUnleashed@n" }
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
    id = "potential_unleashed",
    name = "@cPotential @CUnleashed@n",
    tags = { "transformation", "super_saiyan" },
    exclusive_tags = { "transformation" },
    persistent = true,
    modifiers = modifiers,
}
