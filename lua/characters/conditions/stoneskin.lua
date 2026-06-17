local function modifiers(ch, cond)
    local mods = {}


--    mods[#mods + 1] = { target = { "derived", "constitution" }, kind = "flat", value = 2, label = "Might" }

    return mods
end

return {
    id = "stoneskin",
    name = "Stoneskin",
    tags = { "stoneskin" },
    persistent = true,
    modifiers = modifiers,
}
