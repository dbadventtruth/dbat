local function on_tick(ch, cond)
    if math.random(1, 4) == 4 then
        ch:condition_remove("shocked", "recovered")
    end
end

return {
    id         = "shocked",
    name       = "Shocked",
    tags       = { "shocked" },
    persistent = false,
    legacy_affects = { dbat.consts.aff_flags.SHOCKED },
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
        ch:send_line("@wYour mind is no longer shocked.")
        if ch:skill_get("telepathy") > 0 then
            local old_skill = ch:skill_get("telepathy")
            ch:improve_skill("telepathy", 0)
            while math.random(1, 8) ~= 5 do
                ch:improve_skill("telepathy", 0)
            end
            if ch:skill_get("telepathy") > old_skill then
                ch:send_line("Your mental damage and recovery has taught you things about your own mind.")
            end
        end
    end,
    on_event = function(ch, cond, event)
        if event == "tick" then on_tick(ch, cond) end
    end,
}
