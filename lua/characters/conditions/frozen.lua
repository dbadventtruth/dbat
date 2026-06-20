local function on_tick(ch, cond)
    if math.random(1, 2) == 2 then
        ch:condition_remove("frozen", "thawed")
    end
end

return {
    id         = "frozen",
    name       = "Frozen",
    tags       = { "frozen" },
    persistent = false,
    legacy_affects = { dbat.consts.aff_flags.FROZEN },
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
        ch:send_line("You realize you have thawed enough and break out of the ice holding you prisoner!")
        ch:act_around("$n breaks out of the ice holding $m prisoner!")
    end,
    on_event = function(ch, cond, event)
        if event == "tick" then on_tick(ch, cond) end
    end,
}
