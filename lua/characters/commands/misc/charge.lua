local dbat = require("dbat")
local PLR   = dbat.consts.player_flags
local fmt   = dbat.lib.text.add_commas

local AURA_NAMES = { "white", "blue", "red", "green", "pink", "purple", "yellow", "black", "orange" }

local function aura_name(ch)
    return AURA_NAMES[ch:aura_get() + 1] or "white"
end

local function execute(ctx)
    local ch  = ctx.ch
    local arg = ctx.argparams.tokens[1] or ""

    if arg == "" then
        ch:send_line("Charge, yes. How much percent though?")
        ch:send_line("[ 1 - 100 | cancel | release]")
        return
    end

    if arg == "release" then
        if ch:player_flagged(PLR.CHARGE) and ch:charge_get() <= 0 then
            ch:send_line("Try cancel instead, you have nothing charged up yet!")
            return
        end
        ch:release_charge()
        return
    end

    if arg == "cancel" then
        if not ch:player_flagged(PLR.CHARGE) then
            ch:send_line("You are not even charging!")
            return
        end
        ch:send_line("You stop charging.")
        local r = math.random(1, 3)
        if r == 1 then
            ch:act_around("$n@w's aura disappears.")
        elseif r == 2 then
            ch:act_around("$n@w's aura fades.")
        else
            ch:act_around("$n@w's aura flickers brightly before disappearing.")
        end
        ch:condition_remove("charge", "cancel")
        return
    end

    local amt = tonumber(arg)
    if not amt or amt < 1 then
        ch:send_line("You have set it too low!")
        return
    end
    if amt > 100 then
        ch:send_line("You have set it too high!")
        return
    end

    local maxki     = ch:meter_max("ki")
    local target_ki = math.floor(maxki * 0.01 * amt) + 1

    if ch:condition_has("spirit_control") then
        local cur_ki      = ch:meter_current("ki")
        local charge_amt  = math.min(target_ki, cur_ki)
        local sc_skill    = ch:skill_get("spirit control")
        local spirit_cost = math.floor(maxki * (sc_skill >= 100 and 0.01 or 0.05))

        local chance = math.max(10, math.min(15, 15 - math.floor(sc_skill / 10)))
        if chance > math.random(1, 100) then
            ch:send_line("The rush of ki that you try to pool temporarily overwhelms you and you lose control!")
            ch:condition_remove("spirit_control", "charging")
            return
        end

        ch:reveal_hiding(0)
        ch:send_line(string.format(
            "Your %s colored aura flashes up around you as you instantly take control of the ki you needed!",
            aura_name(ch)))
        ch:send_line(string.format("@D[@RCost@D: @r%s@D]", fmt(spirit_cost)))
        ch:act_around(string.format("@wA %s aura flashes up brightly around $n@w!", aura_name(ch)))
        ch:charge_set(charge_amt)
        ch:meter_mod_int("ki", -(charge_amt + spirit_cost))
        ch:condition_apply_variables("charge", { holding = 1 }, {}, "skill", "charge")
        return
    end

    ch:reveal_hiding(0)
    ch:send_line(string.format(
        "You begin to charge some energy, as a %s aura begins to burn around you!",
        aura_name(ch)))
    ch:act_around(string.format("@wA %s aura flashes up brightly around $n@w!", aura_name(ch)))
    ch:condition_apply_number("charge", "target", target_ki, "skill", "charge")
end

local function can_execute(ch)
    if ch:is_npc() then return false, "" end
    if ch:player_flagged(PLR.AURALIGHT) then
        return false, "@WYou are concentrating too much on your aura to be able to charge."
    end
    if ch:player_flagged(PLR.HEALT) then
        return false, "You are inside a healing tank!"
    end
    if ch:condition_has("mental_break") then
        return false, "Your mind is still strained from psychic attacks..."
    end
    if ch:condition_has("poison") then
        return false, "You feel too sick from the poison to concentrate."
    end
    if ch:meter_current("ki") < ch:meter_max("ki") / 100 then
        return false, "You don't even have enough ki!"
    end
    return true
end

return {
    id       = "charge",
    aliases  = { { "charge", 2 } },
    execute  = execute,
    can_execute = can_execute,
}
