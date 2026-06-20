local function modifiers(ch, cond)
    local mods = {}

    return mods
end

return {
    id = "stone_spit",
    name = "Stone Spit",
    tags = { "status", "paralyze_aff", "remove_on_death" },
    persistent = true,
    modifiers = modifiers,
    legacy_affects = {dbat.consts.aff_flags.PARALYZE,},
}
