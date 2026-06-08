local function pose_bonus(ch)
    local skill = ch:skill_get("special pose")
    if skill < 0 then return 0 end
    if skill > 100 then skill = 100 end
    return skill * 15 -- 100 skill = +15%.
end

return {
    id = "special_pose",
    name = "Special Pose",
    tags = { "pose", "lifeforce_bonus" },
    persistent = false,
    modifiers = function(ch)
        local bonus = pose_bonus(ch)
        local modifiers = {
            { target = { "derived", "strength" }, kind = "flat", value = 8, label = "Special Pose" },
            { target = { "derived", "wisdom" }, kind = "flat", value = 8, label = "Special Pose" },
        }
        if bonus > 0 then
            modifiers[#modifiers + 1] = { target = { "derived", "lifeforce" }, kind = "percent", value = bonus, label = "Special Pose" }
        end
        return modifiers
    end,
    on_remove = function(ch, cond) 
        ch:send_text("You feel slightly less confident now.\r\n")
    end,
}
