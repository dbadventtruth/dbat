local dbat   = require("dbat")
local act    = dbat.lib.act
local search = dbat.lib.search

local PULSE_3SEC = 30  -- 3 * PASSES_PER_SEC (10)

local function execute(ctx)
    local ch = ctx.ch

    if not ch:know_skill("extract") then
        ch:send_line("You do not know how to extract!")
        return
    end

    local tokens = ctx.argparams.tokens
    local arg    = string.lower(tokens[1] or "")
    local arg2   = string.lower(tokens[2] or "")
    local arg3   = string.lower(tokens[3] or "")
    local skill  = ch:skill_get("extract")

    if arg == "" then
        ch:send_line("Syntax: extract (object)")
        ch:send_line("Syntax: extract combine (bottle1) (bottle2)")
        return
    end

    if arg == "combine" then
        local s = search.new(ch)
        s:add_character_inventory(ch)
        local obj  = s:find_one(arg2)
        local obj2 = search.new(ch):add_character_inventory(ch):find_one(arg3)
        if not obj then
            ch:send_line("You do not have the first bottle that you were wanting to combine.")
            return
        end
        if not obj2 then
            ch:send_line("You do not have the second bottle that you were wanting to combine.")
            return
        end
        if obj:vnum_get() ~= 3424 then
            ch:send_line("That is not an ink bottle!")
            return
        end
        if obj2:vnum_get() ~= 3424 then
            ch:send_line("That is not an ink bottle!")
            return
        end
        if obj:value_get(6) <= 0 then
            ch:send_line("There isn't any ink in the first bottle!")
            return
        end
        if obj2:value_get(6) <= 0 then
            ch:send_line("There isn't any ink in the second bottle!")
            return
        end
        if obj:value_get(6) >= obj2:value_get(6) then
            obj:value_set(6, math.min(obj:value_get(6) + obj2:value_get(6), 24))
            ch:send_line("You combine the ink of the two bottles into one bottle, and discard the leftovers.")
            obj2:extract()
        else
            obj2:value_set(6, math.min(obj2:value_get(6) + obj:value_get(6), 24))
            ch:send_line("You combine the ink of the two bottles into one bottle, and discard the leftovers.")
            obj:extract()
        end
        return
    end

    local obj = search.new(ch):add_character_inventory(ch):find_one(arg)
    if not obj then
        ch:send_line("You do not have that item.")
        return
    end

    if obj:vnum_get() ~= 3425 then
        ch:send_line("That is not something you can extract from.")
        return
    end

    -- VAL_MAXMATURE=3, VAL_MATURITY=2
    if obj:value_get(3) ~= 0 and obj:value_get(2) < obj:value_get(3) then
        ch:send_line("It's not mature enough to extract from!")
        return
    end

    local bottle = ch:inventory_find_vnum(3423)
    if not bottle then
        ch:send_line("You do not have an empty bottle to put the extracted ink in.")
        return
    end

    local maxki = ch:meter_max("ki")
    local cost  = math.floor(maxki * 0.35) + 500
    if bottle:value_get(6) + 4 >= 24 then
        cost = cost + math.floor(maxki * 0.5)
    end

    if ch:meter_current("ki") < cost then
        ch:send_line(string.format(
            "You do not have enough ki! @D[@rNeeded@D: @R%s@D]@n",
            dbat.add_commas(cost)))
        return
    end

    ch:meter_mod_int("ki", -cost)

    local act_ctx = { actor = ch, tool = obj }
    if skill < dbat.axion_dice(0) then
        act.to_actor(
            "@WWith your ki flowing carefully into your hands you take a hold of the @G$p@W and begin to strip it of its leaves. Once it has been stripped you go to squeeze the ink carefully from the leaves into the bottle, but unfortunately the ink explodes into a mess instead!@n",
            act_ctx)
        act.around(ch,
            "@C$n@W takes a hold of the @G$p@W and begins to strip it of its leaves. Once it has been stripped $e bundles up the leaves in $s hands and begins to squeeze. A nasty explosion of a mess is all that follows!@n",
            act_ctx)
        ch:improve_skill("extract", 0)
        obj:extract()
        ch:wait_set(PULSE_3SEC)
        return
    end

    act.to_actor(
        "@WWith your ki flowing carefully into your hands you take a hold of the @G$p@W and begin to strip it of its leaves. Once it has been stripped you go to squeeze the ink carefully from the leaves into the bottle, and manage to get every last drop of ink into it.@n",
        act_ctx)
    act.around(ch,
        "@C$n@W takes a hold of the @G$p@W and begins to strip it of its leaves. Once it has been stripped $e bundles up the leaves in $s hands and begins to squeeze ink carefully from the leaves into a bottle.@n",
        act_ctx)
    obj:extract()

    local new_ink = bottle:value_get(6) + math.random(4, 6)
    if new_ink >= 24 then
        local filled = dbat.obj_protos.by_id(3424):spawn()
        bottle:extract()
        filled:value_set(6, 24)
        filled:to_char(ch)
        local ctx2 = { actor = ch, tool = filled }
        act.to_actor("@GAs the last of the ink fills the bottle you infuse a final burst of ki into the bottle.@n", ctx2)
        act.around(ch, "@GAs the last of the ink fills the bottle @g$n@G infuses a final burst of ki into the bottle.@n", ctx2)
    else
        bottle:value_set(6, new_ink)
        ch:send_line("You will need to fill the bottle before giving it a final infusion of ki to complete the process.")
    end

    ch:improve_skill("extract", 0)
    ch:wait_set(PULSE_3SEC)
end

return {
    id      = "extract",
    aliases = { { "extract", 6 } },
    execute = execute,
}
