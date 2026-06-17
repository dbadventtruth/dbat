local function modifiers(ch, cond)
    local mods = {}

    mods[#mods + 1] = { target = { "derived", "agility" }, kind = "flat", value = 10, label = "Flex" }

    return mods
end

return {
    id = "flex",
    name = "Flex",
    tags = { "flex" },
    persistent = true,
    modifiers = modifiers,
}
