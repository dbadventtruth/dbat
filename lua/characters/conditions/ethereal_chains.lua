local function modifiers(ch, cond)
    local mods = {}

    mods[#mods + 1] = { target = { "derived", "speed" }, kind = "flat", value = -3, label = "Ethereal Chains" }

    return mods
end

return {
    id = "ethereal_chains",
    name = "Ethereal Chains",
    tags = { "ethereal_chains" },
    persistent = true,
    modifiers = modifiers,
}
