local function modifiers(ch, cond)
    local mods = {}

    mods[#mods + 1] = { target = { "derived", "strength" }, kind = "flat", value = -3, label = "Wither" }
    mods[#mods + 1] = { target = { "derived", "speed" }, kind = "flat", value = -3, label = "Wither" }

    return mods
end

return {
    id = "wither",
    name = "Wither",
    tags = { "wither", "healthy_clear" },
    persistent = true,
    modifiers = modifiers,
}
