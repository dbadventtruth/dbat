local function level(ch, condition)
    local value = condition:number_get("level")
    if value <= 0 then value = ch:stat_get("kaioken") end
    if value < 0 then return 0 end
    return value
end

local function on_tick(ch, cond)
    local kaioken_level = ch:stat_get("kaioken")
    if kaioken_level <= 0 then return end
    local x = (kaioken_level * 5) + 5
    ch:improve_skill("kaioken", -1)
    local skill = ch:skill_get("kaioken")
    local stamina_low = ch:meter_current("stamina") <= ch:meter_max("stamina") / 10
    if skill < math.random(1, x) or stamina_low then
        ch:send_line("You lose focus and your kaioken disappears.")
        ch:act_around("$n loses focus and $s kaioken aura disappears.")
        ch:stat_set("kaioken", 0)
        ch:condition_remove("kaioken", "kaioken_lost")
    end
end

return {
    id = "kaioken",
    name = "Kaioken",
    tags = { "power_amp", "kaioken" },
    persistent = false,
    modifiers = function(ch, condition)
        local bonus = level(ch, condition) * 1000 -- +10% per Kaioken level.
        if bonus <= 0 then return {} end
        return {
            { target = { "derived", "powerlevel" }, kind = "percent", value = bonus, label = "Kaioken" },
        }
    end,
    on_apply = function(ch, cond)
        if ch:stat_get("kaioken") > 0 then
            cond:schedule_event("tick", 100000, 100000)
        end
    end,
    on_game_activate = function(ch, cond)
        if ch:stat_get("kaioken") > 0 and not cond:event_pending("tick") then
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
