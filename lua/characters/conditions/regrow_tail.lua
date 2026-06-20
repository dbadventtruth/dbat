return {
    id         = "regrow_tail",
    name       = "Regrowing Tail",
    tags       = { "regrow_tail" },
    persistent = true,
    on_apply = function(ch, cond)
        cond:schedule_expire(1200)
    end,
    on_game_activate = function(ch, cond)
        if not cond:event_pending("expire") then
            cond:schedule_expire(1200)
        end
    end,
    on_remove = function(ch, cond)
        ch:gain_tail()
        ch:send_line("@wYour tail grows back.")
        ch:act_around("$n@w's tail grows back.")
    end,
}
