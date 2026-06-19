local dbat  = require("dbat")
local act   = dbat.lib.act

local WEAR  = dbat.consts.wear_positions
local ITEMS = dbat.consts.item_types
local RF    = dbat.consts.room_flags
local FISH  = dbat.consts.fish_states
local APPLY = dbat.consts.applies

local function get_pole(ch)
    local pole = ch:equipment_get(WEAR.WIELD2)
    if pole and pole:type_get() == ITEMS.FISHPOLE then return pole end
end

local function pole_bonus(ch)
    return ch:legacy_modifier(APPLY.ACCURACY, -1)
end

local function catch_fish(ch, bonus)
    local room = ch:room_get()
    if not room then return end

    local r   = math.random(1, 10)
    local num = 1000
    if room:flagged(RF.FISHFRESH) then
        if room:flagged(RF.EARTH) then
            if     r <= 4 then num = 1000
            elseif r <= 7 then num = 1001
            elseif r <= 9 then num = 1002
            else            num = 1003 end
        elseif room:flagged(RF.AETHER) then
            if     r <= 4 then num = 1012
            elseif r <= 7 then num = 1013
            elseif r <= 9 then num = 1014
            else            num = 1015 end
        end
    else
        if room:flagged(RF.EARTH) then
            if     r <= 4 then num = 1004
            elseif r <= 7 then num = 1005
            elseif r <= 9 then num = 1006
            else            num = 1007 end
        elseif room:flagged(RF.NAMEK) then
            if     r <= 4 then num = 1008
            elseif r <= 7 then num = 1009
            elseif r <= 9 then num = 1010
            else            num = 1011 end
        end
    end

    local proto = dbat.obj_protos.by_id(num)
    if not proto then
        dbat.send_to_imm("Error: Fish success with no fish! Report to Iovan!\r\n")
        return
    end
    local fish = proto:spawn()
    if not fish then
        dbat.send_to_imm("Error: Fish success with no fish! Report to Iovan!\r\n")
        return
    end

    local ctx = { actor = ch, tool = fish }
    act.to_actor("@CYou manage to pull a $p@C from the water and onto the ground in front of you!@n", ctx)
    act.around(ch, "@c$n@C manages to pull a $p@C from the water and onto the ground in front of $m!@n", ctx)

    local quality
    if bonus >= math.random(60, 100) then
        quality = math.random(0, 3) + math.random(0, 3) + math.random(0, 3)
    elseif bonus >= math.random(45, 60) then
        quality = math.random(0, 3) + math.random(0, 3)
    else
        quality = math.random(0, 3)
    end

    if quality <= 0 and math.random(1, 20) >= 17 then
        quality = quality + math.random(2, 7)
    end

    local pole     = get_pole(ch)
    local bait_val = pole and pole:value_get(0) or 0
    if bait_val * 2 >= dbat.axion_dice(0) then
        quality = quality + 2
    elseif bait_val >= dbat.axion_dice(0) then
        quality = quality + 1
    end

    local weight
    if quality <= 1 then
        weight = math.random(0, 2)
    elseif quality <= 3 then
        weight = math.random(3, 4)
        fish:cost_set(math.floor(fish:cost_get() * 1.20))
        fish:value_set(0, fish:value_get(0) + 1)
    elseif quality <= 6 then
        weight = math.random(5, 9)
        fish:cost_set(math.floor(fish:cost_get() * 1.5))
        fish:value_set(0, fish:value_get(0) + 3)
    else
        weight = math.random(10, 15)
        fish:cost_set(math.floor(fish:cost_get() * 3))
        fish:value_set(0, fish:value_get(0) + 5)
    end
    fish:weight_mod(weight)

    if pole then pole:value_set(0, 0) end
    fish:to_char(ch)
    ch:send_line(string.format("@D[@cFish Weight@D: @G%d@D]@n", fish:weight_get()))
end

local function on_tick(ch, cond)
    if not ch:condition_has("fishing") then return end

    local pole = get_pole(ch)
    if not pole then
        ch:condition_remove("fishing", "no_pole")
        return
    end

    local bonus    = pole_bonus(ch)
    local room     = ch:room_get()
    local state    = cond:number_get("state")
    local distance = cond:number_get("distance")

    if distance <= 0 and state == FISH.REELING then
        catch_fish(ch, bonus)
        ch:condition_remove("fishing", "caught")
        return
    end

    if math.random(1, 5) <= 2 then return end

    local ctx = { actor = ch }

    if state == FISH.REELING then
        if math.random(1, 100) <= 80 then
            local new_dist = distance
            if bonus >= 80 then
                new_dist = new_dist - math.random(6, 10)
            elseif bonus >= 40 then
                new_dist = new_dist - math.random(5, 8)
            else
                new_dist = new_dist - math.random(1, 4)
            end
            if new_dist ~= distance then
                cond:number_set("distance", new_dist)
            end
            act.to_actor("@CYou reel the line on your pole some.@n", ctx)
            act.around(ch, "@c$n@C reels the line on $s pole slowly.@n", ctx)
            ch:send_line(string.format("@D[@wDistance@D: @Y%d@D]@n", new_dist > 0 and new_dist or 0))
        elseif math.random(1, 58) <= 55 then
            act.to_actor("@CYou struggle as the fish fights against your attempts to reel it in!@n", ctx)
            act.around(ch, "@c$n@C struggles with the fish on the end of $s pole!@n", ctx)
        else
            act.to_actor("@CYou feel the line go slack and realize you've lost the fish! You reel your line back in...@n", ctx)
            act.around(ch, "@c$n@C frowns and then begins to reel in $s line.@n", ctx)
            if pole then pole:value_set(0, 0) end
            ch:condition_remove("fishing", "lost_fish")
        end
    elseif state == FISH.HOOKED then
        if math.random(1, 20) >= 12 then
            act.to_actor("@CYou feel the line go slack and realize you've lost the fish! You reel your line back in...@n", ctx)
            act.around(ch, "@c$n@C frowns and then begins to reel in $s line.@n", ctx)
            ch:condition_remove("fishing", "lost_fish")
        end
    elseif state == FISH.BITE then
        if math.random(1, 20) >= 12 then
            act.to_actor("@CYou feel as if the fish has stopped biting...@n", ctx)
            cond:number_set("state", FISH.NOFISH)
        end
    elseif state == FISH.NOFISH then
        local bite_chance
        if room and room:flagged(RF.FISHFRESH) then
            bite_chance = math.random(1, 10) >= 8
        else
            bite_chance = math.random(1, 20) >= 18
        end
        if bite_chance then
            act.to_actor("@CYou feel a fish biting on your line! Better @Ghook@C it!@n", ctx)
            cond:number_set("state", FISH.BITE)
        end
    end
end

local function on_hook(ch, cond)
    local state = cond:number_get("state")
    if state == FISH.NOFISH then
        ch:send_line("You do not have a fish biting on your line.")
        return
    end
    if state == FISH.REELING then
        ch:send_line("You are already trying to reel the fish in!")
        return
    end
    if state == FISH.HOOKED then
        ch:send_line("You already have the fish hooked! Reel it in!")
        return
    end
    ch:reveal_hiding(0)
    local ctx = { actor = ch }
    if dbat.axion_dice(-18) > pole_bonus(ch) then
        act.to_actor("@CYou pull hard but the fish spits the hook out a second before you pull! You return to waiting for a bite...@n", ctx)
        act.around(ch, "@c$n@C pulls hard on $s fishing line, but a moment later $e frowns and returns to fishing.@n", ctx)
        cond:number_set("state", FISH.NOFISH)
    else
        act.to_actor("@CYou pull hard on your line and feel that you have managed to hook the fish and start reeling it in!@n", ctx)
        act.around(ch, "@c$n@C pulls hard on $s fishing line and starts to struggle with the fish on the other end!@n", ctx)
        cond:number_set("state", FISH.REELING)
    end
end

local function on_stop(ch, cond)
    ch:reveal_hiding(0)
    local ctx = { actor = ch }
    act.to_actor("@CYou reel in your line and stop fishing.@n", ctx)
    act.around(ch, "@c$n@C reels in $s fishing line and stops fishing.@n", ctx)
    ch:condition_remove("fishing", "fish_stop")
end

return {
    id         = "fishing",
    name       = "Fishing",
    tags       = { "fishing" },
    persistent = false,

    on_apply = function(ch, cond)
        cond:schedule_event("tick", 2000, 2000)
    end,

    on_game_activate = function(ch, cond)
        if not cond:event_pending("tick") then
            cond:schedule_event("tick", 2000, 2000)
        end
    end,

    on_remove = function(ch, cond, reason)
        cond:cancel_event("tick")
    end,

    on_event = function(ch, cond, event)
        if event == "tick" then
            on_tick(ch, cond)
        elseif event == "hook" or event == "reel" then
            on_hook(ch, cond)
        elseif event == "stop" then
            on_stop(ch, cond)
        end
    end,

    status_line = function(ch, cond)
        local bonus = ch:legacy_modifier(APPLY.ACCURACY, -1)
        return string.format("Current Fishing Pole Bonus @D[@C%d@D]@n", bonus)
    end,
}
