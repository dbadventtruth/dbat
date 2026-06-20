return {
    id         = "knocked_out",
    name       = "Knocked Out",
    tags       = { "knocked" },
    persistent = false,
    legacy_affects = { dbat.consts.aff_flags.KNOCKED },
    on_remove = function(ch, cond, reason)
        if reason ~= "recovered_silent" then
            ch:act_around("$n is no longer senseless, and wakes up.")
            ch:send_line("You are no longer knocked out, and wake up!")
        end
        ch:position_set(dbat.consts.positions.SITTING)
    end,
}
