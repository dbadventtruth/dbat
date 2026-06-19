local dbat    = require("dbat")
local SECT    = dbat.consts.sector_types
local RF      = dbat.consts.room_flags
local P       = dbat.consts.pulses

local function execute(ctx)
    local ch   = ctx.ch
    local room = ch:room_get()
    local skill = ch:skill_get("dimizu")

    if room:geffect_get() < 0 then
        ch:send_line("@CYou concentrate and distabilie the water, separating the hydrogen and oxygen. The gases dissipate quickly.")
        ch:act_around("@c$n@C concentrates and the water filling the area seems to shudder. Suddenly the water begins to evaporate as the hydrogen and oxygen are separated.")
        room:geffect_set(0)
        ch:wait_set(P.one_sec)
        return
    end

    if room:sector_type_get() == SECT.UNDERWATER then
        ch:send_line("The area is already underwater!")
        return
    end

    if room:sector_type_get() == SECT.SPACE or room:flagged(RF.SPACE) then
        ch:send_line("You can't flood space!")
        return
    end

    local ki_max = ch:meter_max("ki")
    if ch:meter_current("ki") < math.floor(ki_max / 12) then
        ch:send_line("You do not have enough ki to perform the technique.")
        return
    end

    if skill < dbat.axion_dice(0) then
        ch:send_line("@CYou gather your ki and concentrate on creating water from it. Water begins to flow upward around the entire area, but you lose your concentration and it all goes flooding away!@n")
        ch:act_around("@c$n@C gathers $s ki and concentrates on creating water from it. Water begins to flow upward around the entire area, but $e loses $s concentration and all the water goes flooding away!@n")
        ch:meter_mod("ki", -math.floor(ki_max / 12))
        ch:improve_skill("dimizu", 0)
        return
    end

    ch:send_line("@CYou gather your ki and concentrate on creating water from it. Water begins to flow upward around the entire area. You form the water into a perfect cube with barely any ripples in its walls. It will maintain this form for a while.@n")
    ch:act_around("@c$n@C gathers $s ki and concentrates on creating water from it. Water begins to flow upward around the entire area. @c$n@C forms the water into a perfect cube with barely any ripples in its walls. It appears the water will maintain this form for a while.@n")
    ch:meter_mod("ki", -math.floor(ki_max / 12))
    room:geffect_set(-3)
    ch:improve_skill("dimizu", 0)
end

local function can_execute(ch)
    if ch:is_npc() then return false end
    if not ch:know_skill("dimizu") then return false end
    return true
end

return { id = "dimizu", aliases = { { "dimizu", 3 } }, execute = execute, can_execute = can_execute }
