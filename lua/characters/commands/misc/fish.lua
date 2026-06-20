local dbat   = require("dbat")
local act    = dbat.lib.act
local search = dbat.lib.search

local WEAR  = dbat.consts.wear_positions
local ITEMS = dbat.consts.item_types
local RF    = dbat.consts.room_flags

local function get_pole(ch)
    local pole = ch:equipment_get(WEAR.WIELD2)
    if pole and pole:type_get() == ITEMS.FISHPOLE then return pole end
end

local function dispatch(ch, event)
    local def = dbat.registry.conditions["fishing"]
    if def and def.on_event then
        def.on_event(ch, ch:condition("fishing"), event)
    end
end

local function execute(ctx)
    local ch   = ctx.ch
    if ch:is_npc() then return end

    local toks = ctx.argparams.tokens
    local arg1 = string.lower(toks[1] or "")
    local arg2 = string.lower(toks[2] or "")

    if arg1 == "" then
        ch:send_line("Syntax: fish ( cast | hook | reel | apply | stop)")
        return
    end

    if arg1 == "apply" then
        local pole = get_pole(ch)
        if not pole then
            ch:send_line("You are not holding a fishing pole.")
            return
        end
        if pole:value_get(0) ~= 0 then
            ch:send_line("Your fishing pole already has bait on its hook.")
            return
        end
        if arg2 == "" then
            ch:send_line("Syntax: fish apply (bait)")
            return
        end
        local bait = search.new(ch)
            :add_character_inventory(ch)
            :add_filter(function(s, e) return e:type_get() == ITEMS.FISHBAIT end)
            :find_one(arg2)
        if not bait then
            ch:send_line("You don't have that bait.")
            return
        end
        ch:reveal_hiding(0)
        local ctx2 = { actor = ch, tool = bait }
        act.to_actor("@CYou carefully apply the $p@C to your hook.@n", ctx2)
        act.around(ch, "@c$n@C carefully applies $p@C to $s fishing pole's hook.@n", ctx2)
        pole:value_set(0, bait:cost_get())
        bait:extract()
        return
    end

    if arg1 == "cast" then
        if ch:condition_has("fishing") then
            ch:send_line("You are already fishing! Syntax: fish stop")
            return
        end
        local room = ch:room_get()
        if not room or not room:flagged(RF.FISHING) then
            ch:send_line("This is not an area you can fish at.")
            return
        end
        if ch:condition_has("flying") then
            ch:send_line("You can't fish while flying.")
            return
        end
        if ch:condition_has("fighting") then
            ch:send_line("You can't fish while fighting!")
            return
        end
        local pole = get_pole(ch)
        if not pole then
            ch:send_line("You are not holding a fishing pole.")
            return
        end
        if pole:value_get(0) == 0 then
            ch:send_line("There is no bait on your line!")
            return
        end
        ch:reveal_hiding(0)
        local ctx2 = { actor = ch }
        act.to_actor("@CYou pull your arm back and then spring it forward, casting the baited line. A moment later there is a splash as the hook enters the water.@n", ctx2)
        act.around(ch, "@c$n@C pulls $s arm back and then springs it foward, casting the line of $s fishing pole into the water.@n", ctx2)
        local distance = math.random(30, 80)
        ch:condition_apply_number("fishing", "distance", distance, "player", "fish_cast")
        ch:send_line(string.format("@D[@wDistance@D: @Y%d@D]@n", distance))
        return
    end

    if arg1 == "hook" or arg1 == "reel" or arg1 == "stop" then
        if not ch:condition_has("fishing") then
            ch:send_line("You are not even fishing!")
            return
        end
        dispatch(ch, arg1)
        return
    end

    ch:send_line("Syntax: fish ( cast | hook | reel | apply | stop )")
end

return { id = "fish", aliases = { { "fish", 3 } }, execute = execute }
