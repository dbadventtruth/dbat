return {
    id             = "arlian_shell",
    name           = "Arlian Shell",
    tags           = { "arlian_shell" },
    persistent     = false,
    legacy_affects = { dbat.consts.aff_flags.SHELL },
    modifiers      = function(ch, cond)
        return {
            { target = { "derived", "speed_index" }, kind = "percent", value = -5000, label = "Arlian Shell" },
        }
    end,
}
