local function modifiers(ch, cond)
    local mods = {}


--    mods[#mods + 1] = { target = { "derived", "constitution" }, kind = "flat", value = 2, label = "Might" }

    return mods
end

return {
    id = "hasshuken",
    name = "Hasshuken",
    tags = { "hasshuken" },
    persistent = true,
    modifiers = modifiers,
}
