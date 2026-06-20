local function on_tick(ch, cond)
    local con = ch:stat_get("constitution")
    local cost = con >= 100 and 0.01 or con >= 80 and 0.02 or con >= 50 and 0.03
               or con >= 30 and 0.04 or con >= 20 and 0.05 or 0.06
    local maxhp = ch:meter_max("health")
    if ch:meter_current("health") - maxhp * cost > 0 then
        ch:send_line("You puke as the poison burns through your blood.")
        ch:act_around("$n shivers and then pukes.", {hide_invisible = true})
        ch:meter_mod("health", -math.floor(maxhp * cost))
    else
        ch:send_line("The poison claims your life!")
        ch:act_around("$n pukes up blood and falls down dead!", {hide_invisible = true})
        ch:die(cond:number_get("poison_by"))
    end
end

return {
    id = "poison",
    name = "Poison",
    tags = { "poison", "affliction", "healthy_clear" },
    persistent = false,
    modifiers = function()
        return {
            { target = { "regen", "vitals" }, kind = "multiplier", value = -7500, label = "Poison" },
        }
    end,
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
