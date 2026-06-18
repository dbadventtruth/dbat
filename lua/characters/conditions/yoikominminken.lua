local function modifiers(ch, cond)
    local mods = {}

    return mods
end

return {
    id = "yoikominminken",
    name = "Yoikominminken",
    tags = { "status", "sleep_aff", "remove_on_death" },
    persistent = true,
    modifiers = modifiers,
    legacy_affects = {dbat.consts.aff_flags.SLEEP,},
}
