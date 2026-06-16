local function modifiers(ch, cond)
    local mods = {}

    mods[#mods + 1] = { target = { "derived", "speed" }, kind = "flat", value = -3, label = "Shadow Stitch" }

    return mods
end

return {
    id = "shadow_stitch",
    name = "Shadow Stitch",
    tags = { "shadow_stitch", "debuff" },
    persistent = true,
    modifiers = modifiers,
}
