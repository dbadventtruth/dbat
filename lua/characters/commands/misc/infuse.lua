local dbat = require("dbat")
local AFF  = dbat.consts.aff_flags

local function execute(ctx)
    local ch = ctx.ch

    if not ch:know_skill("infuse") then return end

    if ch:aff_flagged(AFF.INFUSE) then
        ch:send_line("You stop infusing ki into your attacks.")
        ch:act_around("$n stops infusing ki into $s attacks.")
        ch:aff_flag_set(AFF.INFUSE, false)
        return
    end

    local ki_max = ch:meter_max("ki")
    if ch:meter_current("ki") < math.floor(ki_max / 100) then
        ch:send_line("You don't have enough ki to infuse into your attacks!")
        return
    end

    ch:reveal_hiding(0)
    ch:send_line("You start infusing ki into your attacks.")
    ch:act_around("$n starts infusing ki into $s attacks.")
    ch:aff_flag_set(AFF.INFUSE, true)
    ch:meter_mod("ki", -math.floor(ki_max / 100))
end

return { id = "infuse", aliases = { { "infuse", 2 } }, execute = execute }
