local function modifiers(ch, cond)
    local mods = {}


--    mods[#mods + 1] = { target = { "derived", "constitution" }, kind = "flat", value = 2, label = "Might" }

    return mods
end

return {
    id = "ethereal_armor",
    name = "Ethereal Armor",
    tags = { "ethereal_armor" },
    persistent = true,
    modifiers = modifiers,
}
