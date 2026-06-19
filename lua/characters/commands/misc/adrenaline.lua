local dbat = require("dbat")

local SYNTAX = "Syntax: adrenaline (pl or ki) (percent)\nExample: adrenaline pl 10"

local function execute(ctx)
    local ch   = ctx.ch
    local arg1 = (ctx.argparams.tokens[1] or ""):lower()
    local arg2 = ctx.argparams.tokens[2] or ""

    if arg1 == "" or arg2 == "" then
        ch:send_line(SYNTAX)
        return
    end

    local pct = tonumber(arg2)
    if not pct or pct < 0 or pct > 100 then
        ch:send_line(string.format("The percent must be between 1 and 100%%."))
        return
    end

    local percent = pct * 0.01
    local base_st = ch:meter_max("stamina")
    local trade   = math.floor(base_st * percent)

    local base_pl = ch:meter_max("powerlevel")
    if ch:meter_current("stamina") - math.floor(base_pl * percent) < 0 then
        ch:send_line("You do not have enough stamina to trade for adrenaline!")
        return
    end

    if arg1 == "pl" then
        ch:send_line("@GYou focus your mind and begin to overwork your powerful adrenal glands and your wounds begin to heal!@n")
        ch:act_around("@g$n@G seems to concentrate and $s wounds begin to heal!@n")
        if ch:meter_current("powerlevel") + trade > ch:meter_max("powerlevel") then
            ch:send_line("Some of your stamina was wasted because your powerlevel maxed out.")
        end
        ch:meter_mod("powerlevel", trade)
        ch:meter_mod("stamina", -trade)
    elseif arg1 == "ki" then
        ch:send_line("@GYou focus your mind and begin to overwork your powerful adrenal glands and you feel your ki replenish!@n")
        ch:act_around("@g$n@G seems to concentrate and $e appears energized!@n")
        if ch:meter_current("ki") + trade > ch:meter_max("ki") then
            ch:send_line("Some of your stamina was wasted because your ki maxed out.")
        end
        ch:meter_mod("ki", trade)
        ch:meter_mod("stamina", -trade)
    else
        ch:send_line(SYNTAX)
    end
end

local function can_execute(ch)
    local race = ch:race_get()
    if race == "arlian" then return true end
    if race == "bio" then
        if ch:genome_get(0) == 6 or ch:genome_get(1) == 6 then return true end
    end
    return false, "You are not an arlian and do not possess this ability"
end

return { id = "adrenaline", aliases = { { "adrenaline", 3 } }, execute = execute, can_execute = can_execute }
