local function data(ch)
    return { bonus = 1000000, mult = 20000, name = "@YMature@n" }
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
    id = "mature",
    name = "@YMature@n",
    tags = { "transformation", "bio_android" },
    exclusive_tags = { "transformation" },
    persistent = true,
    modifiers = modifiers,
}
