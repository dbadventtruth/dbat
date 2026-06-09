local function modifiers(ch, cond)
    local mods = {}

    for _, c in ipairs({"strength", "intelligence", "constitution", "speed", "agility", "wisdom"}) do
        mods[#mods + 1] = { target = { "derived", c }, kind = "percent", value = -2000, label = "Resurrection Weakness" }
    end

    return mods
end

return {
    id = "resurrection_weakness",
    name = "Resurrection Weakness",
    tags = { "resurrection", "weakness" },
    persistent = true,
    modifiers = modifiers,
}
