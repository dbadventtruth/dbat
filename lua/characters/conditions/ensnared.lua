local function on_tick(ch, cond)
    if math.random(1, 3) == 2 then
        ch:condition_remove("ensnared", "broke_free")
    end
end

return {
    id         = "ensnared",
    name       = "Ensnared",
    tags       = { "ensnared" },
    persistent = false,
    legacy_affects = { dbat.consts.aff_flags.ENSNARED },
    on_apply = function(ch, cond)
        cond:schedule_event("tick", 100000, 100000)
    end,
    on_game_activate = function(ch, cond)
        if not cond:event_pending("tick") then
            cond:schedule_event("tick", 100000, 100000)
        end
    end,
    on_remove = function(ch, cond, reason)
        cond:cancel_event("tick")
        if reason ~= "equipped" then
            ch:send_line("The silk ensnaring your arms disolves enough for you to break it!")
        end
    end,
    on_event = function(ch, cond, event)
        if event == "tick" then on_tick(ch, cond) end
    end,
}
