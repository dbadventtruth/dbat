local function modifiers(ch, cond)
    local mods = {}

    return mods
end

return {
    id = "yoikominminken",
    name = "Yoikominminken",
    tags = { "status" },
    persistent = true,
    modifiers = modifiers,
    legacy_affects = {dbat.consts.aff_flags.SLEEP,},
}
