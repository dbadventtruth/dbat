local POS = dbat.consts.positions

local function on_tick(ch, cond)
    if ch:position_get() ~= POS.SLEEPING then return end
    if math.random(1, 3) ~= 3 then return end
    if not ch:meter_is_full("health") then return end
    if not ch:meter_is_full("stamina") then return end
    if not ch:meter_is_full("ki") then return end
    ch:send_line("You FINALLY wake up.")
    ch:act_around("$n wakes up.")
    ch:position_set(POS.SITTING)
end

return {
    id          = "bonus_late",
    name        = "Late",
    tags        = { "bonus" },
    persistent  = false,
    description = "Late Sleeper - Can only wake automatically. 33% every hour if maxed",
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
    end,
    on_event = function(ch, cond, event)
        if event == "tick" then on_tick(ch, cond) end
    end,
}
