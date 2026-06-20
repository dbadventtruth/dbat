local dbat = require("dbat")

local function execute(ctx)
    local ch = ctx.ch

    if not ch:know_skill("spirit_control") then
        return
    end

    if ch:condition_has("spirit_control") then
        ch:send_line("You have already concentrated and have full control of your spirit.")
        return
    end

    local cost = math.floor(ch:meter_max("ki") * 0.2)
    if ch:meter_current("stamina") < cost then
        ch:send_line(string.format("You need at least 20%% of your max ki in stamina to prepare this skill."))
        return
    end

    ch:meter_mod("stamina", -cost)
    ch:send_line("@YYou concentrate and quantify every last bit of your spiritual and mental energies. You have full control of them and can bring them forth in an instant.@n")
    ch:act_around("@y$n@Y seems to concentrate hard for a moment.@n")

    local duration = math.random(2, 4) * dbat.consts.secs_per_mud_hour
    ch:condition_apply_with_duration("spirit_control", "spirit", "control", duration)
end

return { id = "spiritcontrol", aliases = { { "spiritcontrol", 8 } }, execute = execute }
