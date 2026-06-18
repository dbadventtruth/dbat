local function modifiers(ch, cond)
    local mods = {}

    return mods
end

return {
    id = "paralyze",
    name = "Paralyze",
    tags = { "status", "healthy_clear", "paralyze_aff", "remove_on_death" },
    persistent = true,
    modifiers = modifiers,
}
