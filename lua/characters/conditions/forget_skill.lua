return {
    id         = "forget_skill",
    name       = "Forgetting Skill",
    persistent = true,

    on_apply = function(ch, cond)
        local skill_name = cond:string_get("skill_name")
        if skill_name and skill_name ~= "" then
            cond:schedule_event(ch, "tick", 60000, 60000)
        end
    end,

    on_game_activate = function(ch, cond)
        if not cond:event_pending(ch, "tick") then
            local skill_name = cond:string_get("skill_name")
            if skill_name and skill_name ~= "" then
                cond:schedule_event(ch, "tick", 60000, 60000)
            end
        end
    end,

    on_game_deactivate = function(ch, cond)
        cond:cancel_event(ch, "tick")
    end,

    on_remove = function(ch, cond, reason)
        cond:cancel_event(ch, "tick")
    end,

    on_event = function(ch, cond, event)
        if event ~= "tick" then return end
        local skill_name = cond:string_get("skill_name")
        if not skill_name or skill_name == "" then return end
        local count = cond:number_mod("forget_count", 1)
        if count >= 5 then
            ch:skill_base_set(skill_name, 0)
            ch:send_line(string.format("@MYou have finally forgotten %s.@n", skill_name))
            ch:condition_remove("forget_skill", "completed")
        end
    end,
}
