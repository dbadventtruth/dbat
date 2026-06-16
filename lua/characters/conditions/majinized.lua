local function modifiers(ch, cond)
    local mods = {}

    local bonus = ch:condition_number_get("majinized", "bonus")
    if bonus ~= 0 then
        mods[#mods + 1] = { target = { "derived", "powerlevel" }, kind = "flat", value = bonus, label = "Majinized" }
    end

    return mods
end

return {
    id = "majinized",
    name = "Majinized",
    tags = { "majinized" },
    persistent = true,
    modifiers = modifiers,
}
