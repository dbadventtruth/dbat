return {
    id = "kyodaika",
    name = "@GKyodaika@n",
    tags = { "kyodaika" },
    persistent = true,
    modifiers = function(ch)
        return {
            { target = { "derived", "strength" }, kind = "flat", value = 5, label = "Kyodaika" },
            { target = { "derived", "speed" }, kind = "flat", value = -2, label = "Kyodaika" },
            { target = { "derived", "height" }, kind = "multiplier", value = 100000, label = "Kyodaika" },
            { target = { "derived", "weight" }, kind = "multiplier", value = 500000, label = "Kyodaika" },
        }
    end,
    on_apply = function(ch)
        ch:send_line("@GYou growl as your body grows to ten times its normal size!@n")
        ch:act_around("@g$n@G growls as $s body grows to ten times its normal size!@n")
        ch:send_line("@cStrength@D: @C+5\r\n@cSpeed@D: @c-2@n")
    end,
    on_remove = function(ch)
        ch:send_line("@GYou growl as your body shrinks to its normal size!@n")
        ch:act_around("@g$n@G growls as $s body shrinks to its normal size!@n")
        ch:send_line("@cStrength@D: @C-5\r\n@cSpeed@D: @c+2@n")
    end,
    status_line = function(ch, cond) return "You have used kyodaika." end,
}
