return {
    id       = "gold",
    priority = 0,
    aliases  = {{"gold", 3}},
    execute  = function(ctx)
        local ch = ctx.ch
        local gold = ch:stat_get("money")

        if gold == 0 then
            ch:send_line("You're broke!")
        elseif gold == 1 then
            ch:send_line("You have one little zenni.")
        else
            ch:send_line("You have %d zenni.", gold)
        end
    end,
}
