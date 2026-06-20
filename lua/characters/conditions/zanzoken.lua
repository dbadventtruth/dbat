return {
    id         = "zanzoken",
    name       = "Zanzoken",
    tags       = { "zanzoken" },
    persistent = false,
    status_line = function(ch, cond) return "You are prepared to zanzoken." end,
    on_apply = function(ch, cond)
        cond:schedule_expire(30 + ch:skill_get("zanzoken"))
    end,
    on_remove = function(ch, cond, reason)
        ch:send_line("You lose concentration and no longer are ready to zanzoken.")
    end,
}
