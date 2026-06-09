local function modifiers(ch, cond)
    local mods = {}

    mods[#mods + 1] = { target = { "derived", "speed" }, kind = "flat", value = 5, label = "Future Sight" }
    mods[#mods + 1] = { target = { "derived", "intelligence" }, kind = "flat", value = 2, label = "Future Sight" }

    return mods
end

return {
    id = "future_sight",
    name = "Future Sight",
    tags = { "future", "sight" },
    persistent = true,
    modifiers = modifiers,
}
