local FORGET_LABELS = {
    [0] = "@GRemembered Well@n",
    [1] = "@GRemembered Well Enough@n",
    [2] = "@RGetting Foggy@n",
    [3] = "@RHalf Forgotten@n",
    [4] = "@rAlmost Forgotten@n",
    [5] = "@rForgotten@n",
}

return {
    id         = "forget_skill",
    name       = "Forgetting Skill",
    persistent = true,

    on_apply = function(ch, cond)
        local skill_name = cond:string_get("skill_name")
        if skill_name and skill_name ~= "" then
            cond:schedule_event("tick", 60000, 60000)
        end
    end,

    on_game_activate = function(ch, cond)
        if not cond:event_pending("tick") then
            local skill_name = cond:string_get("skill_name")
            if skill_name and skill_name ~= "" then
                cond:schedule_event("tick", 60000, 60000)
            end
        end
    end,

    on_game_deactivate = function(ch, cond)
        cond:cancel_event("tick")
    end,

    on_remove = function(ch, cond, reason)
        cond:cancel_event("tick")
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

    status_line = function(ch, cond)
        local skill_name = cond:string_get("skill_name") or "unknown"
        local count = math.max(0, math.min(5, cond:number_get("forget_count")))
        local label = FORGET_LABELS[count] or FORGET_LABELS[5]
        return string.format("@MForgetting @D[@m%s - %s@D]@n", skill_name, label)
    end,
}
