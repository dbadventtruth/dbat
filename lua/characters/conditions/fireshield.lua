local function on_tick(ch, cond)
    if ch:is_fighting() then return end
    if math.random(1, 101) > ch:skill_get("fireshield") then
        ch:condition_remove("fireshield", "expired")
    end
end

return {
    id         = "fireshield",
    name       = "Fireshield",
    tags       = { "fireshield" },
    persistent = false,
    legacy_affects = { dbat.consts.aff_flags.FIRESHIELD },
    on_apply = function(ch, cond)
        cond:schedule_event("tick", 100000, 100000)
    end,
    on_game_activate = function(ch, cond)
        if not cond:event_pending("tick") then
            cond:schedule_event("tick", 100000, 100000)
        end
    end,
    on_remove = function(ch, cond)
        cond:cancel_event("tick")
        ch:send_line("Your fireshield disappears.")
    end,
    on_event = function(ch, cond, event)
        if event == "tick" then on_tick(ch, cond) end
    end,
}
