local function modifiers(ch, cond)
    local mods = {}

    mods[#mods + 1] = { target = { "derived", "strength" }, kind = "flat", value = 10, label = "Might" }
    mods[#mods + 1] = { target = { "derived", "constitution" }, kind = "flat", value = 2, label = "Might" }

    return mods
end

return {
    id = "might",
    name = "Might",
    tags = { "might" },
    persistent = true,
    modifiers = modifiers,
}
