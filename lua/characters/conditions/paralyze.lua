local function modifiers(ch, cond)
    local mods = {}

    return mods
end

return {
    id = "paralyze",
    name = "Paralyze",
    tags = { "status", "healthy_clear" },
    persistent = true,
    modifiers = modifiers,
}
