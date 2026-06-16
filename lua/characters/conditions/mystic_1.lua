local function data(ch)
    return { bonus = 1100000, mult = 30000, name = "@YMystic @WFirst@n" }
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
    id = "mystic_1",
    name = "@YMystic @WFirst@n",
    tags = { "transformation", "mystic" },
    exclusive_tags = { "transformation" },
    persistent = true,
    modifiers = modifiers,
}
