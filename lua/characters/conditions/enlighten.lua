local function modifiers(ch, cond)
    local mods = {}

    mods[#mods + 1] = { target = { "derived", "wisdom" }, kind = "flat", value = 10, label = "Enlighten" }

    return mods
end

return {
    id = "enlighten",
    name = "Enlighten",
    tags = { "enlighten" },
    persistent = true,
    modifiers = modifiers,
}
