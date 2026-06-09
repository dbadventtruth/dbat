local function modifiers(ch, cond)
    local mods = {}

    mods[#mods + 1] = { target = { "derived", "intelligence" }, kind = "flat", value = 10, label = "Genius" }

    return mods
end

return {
    id = "genius",
    name = "Genius",
    tags = { "genius" },
    persistent = true,
    modifiers = modifiers,
}
