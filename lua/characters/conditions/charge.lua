local dbat = require("dbat")
local PLR   = dbat.consts.player_flags
local BONUS = dbat.consts.bonus_flags
local POS   = dbat.consts.positions
local PREF  = dbat.consts.preferences

local function schedule_leak(cond)
    cond:schedule_event("leak", 4000, 4000)
end

local function stop_building(ch, cond)
    cond:cancel_event("build")
    ch:player_flag_set(PLR.CHARGE, false)
end

local function on_build(ch, cond)
    local pos = ch:position_get()
    if pos == POS.SLEEPING or pos == POS.RESTING then
        ch:send_line("You stop charging and release all your pent up energy!")
        ch:release_charge()
        return
    end

    if ch:bonus_flagged(BONUS.UNFOCUSED) and math.random(1, 80) >= 70 then
        ch:send_line("You lose concentration due to your unfocused mind and release your charged energy!")
        ch:release_charge()
        return
    end

    local maxki = ch:meter_max("ki")
    local cur = cond:number_get("amount")

    if cur >= maxki / 2 then
        ch:improve_skill("concentration", 1)
    end

    local target = cond:number_get("target")

    if cur >= target then
        ch:send_line("You have already reached the maximum that you wished to charge.")
        ch:act_around("$n@w's aura burns steadily.")
        stop_building(ch, cond)
        schedule_leak(cond)
        return
    end

    local conc = ch:skill_get("concentration")
    local perc
    if     conc > 74 then perc = 10
    elseif conc > 49 then perc = 5
    elseif conc > 24 then perc = 2
    else                  perc = 1
    end

    local race = ch:race_get()
    if race == "truffle" then
        if     perc == 10 then perc = perc + 10
        elseif perc == 5  then perc = perc + 5
        elseif perc == 2  then perc = perc + 3
        else                   perc = perc + 1
        end
    end
    if race == "mutant" and perc > 1 then perc = perc - 1 end
    if ch:preference_get() == PREF.H2H and perc > 1 then perc = math.floor(perc / 2) end

    local base = math.floor(maxki * 0.01 * perc)
    local step = base + 1
    local cur_ki = ch:meter_current("ki")

    if cur_ki <= 0 then
        ch:send_line("You can not charge anymore, you have charged all your energy!")
        ch:act_around("$n@w's aura grows calm.")
        stop_building(ch, cond)
        schedule_leak(cond)
        return
    end

    if base >= cur_ki then
        ch:send_line("You have charged the last that you can.")
        ch:act_around("$n@w's aura @Yflashes@w spectacularly, rushing upwards in torrents!")
        cond:number_set("amount", cur + cur_ki)
        ch:meter_mod_int("ki", -cur_ki)
        stop_building(ch, cond)
        cond:number_set("target", 0)
        schedule_leak(cond)
        return
    end

    if cur + step >= target then
        local deficit = target - cur
        ch:meter_mod_int("ki", -deficit)
        cond:number_set("amount", target)
        ch:send_line("You stop charging as you reach the maximum that you wished to charge.")
        ch:act_around("$n@w's aura flares up brightly and then burns steadily.")
        stop_building(ch, cond)
        cond:number_set("target", 0)
        schedule_leak(cond)
        return
    end

    ch:meter_mod_int("ki", -step)
    cond:number_mod("amount", step)

    local r = math.random(1, 3)
    if r == 1 then
        ch:act_around("$n@w's aura ripples magnificantly while growing brighter!")
        ch:send_line("Your aura grows bright as you charge more ki.")
    elseif r == 2 then
        ch:act_around("$n@w's aura ripples with power as it grows larger!")
        ch:send_line("Your aura ripples with power as you charge more ki.")
    else
        ch:act_around("$n@w's aura throws sparks off violently!.")
        ch:send_line("Your aura throws sparks off violently as you charge more ki.")
    end

    if conc > 0 then ch:improve_skill("concentration", 1) end
end

local function on_leak(ch, cond)
    local cur = cond:number_get("amount")
    if cur <= 0 then
        ch:condition_remove("charge", "depleted")
        return
    end

    local maxki = ch:meter_max("ki")
    if not ch:is_fighting() and
       (ch:preference_get() ~= PREF.KI or cur > maxki * 0.1) then
        if math.random(1, 40) >= 38 then
            if cur >= maxki / 100 then
                ch:send_line("You lose some of your energy slowly.")
                local r = math.random(1, 3)
                if r == 1 then
                    ch:act_around("$n@w's aura flickers weakly.")
                elseif r == 2 then
                    ch:act_around("$n@w's aura sheds energy.")
                else
                    ch:act_around("$n@w's aura flickers brightly before growing dimmer.")
                end
                cond:number_set("amount", cur - math.floor(cur / 20))
            else
                ch:send_line("Your charged energy is completely gone as your aura fades.")
                ch:act_around("$n@w's aura fades away dimmly.")
                cond:number_set("amount", 0)
                ch:condition_remove("charge", "depleted")
            end
        end
    end
end

return {
    id         = "charge",
    name       = "Charging",
    tags       = { "charge" },
    persistent = false,
    on_apply = function(ch, cond)
        if cond:number_get("holding") ~= 0 then
            schedule_leak(cond)
        else
            ch:player_flag_set(PLR.CHARGE, true)
            cond:schedule_event("build", 200, 200)
        end
    end,
    on_remove = function(ch, cond, reason)
        cond:cancel_event("build")
        cond:cancel_event("leak")
        ch:player_flag_set(PLR.CHARGE, false)
        if reason ~= "released" then
            cond:number_set("amount", 0)
        end
    end,
    on_event = function(ch, cond, event)
        if event == "build" then on_build(ch, cond)
        elseif event == "leak" then on_leak(ch, cond) end
    end,
}
