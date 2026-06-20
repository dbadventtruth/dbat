local function data(ch)
    return { bonus = 400000, mult = 20000, name = "@YTransform @WFirst@n" }
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
        { target = { "derived", "height" }, kind = "multiplier", value = 30000, label = form.name },
        { target = { "derived", "weight" }, kind = "multiplier", value = 40000, label = form.name },
    }
end

return {
    id = "icer_transform_1",
    name = "@YTransform @WFirst@n",
    tags = { "transformation", "icer_transform" },
    exclusive_tags = { "transformation" },
    persistent = true,
    modifiers = modifiers,
}
