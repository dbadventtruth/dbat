local dbat = require("dbat")

local TELEPORT_PLANETS = {
    earth = 4, konack = 5, arlia = 6, namek = 7,
    vegeta = 8, frigid = 9, aether = 10, kanassa = 11,
}

local function find_instrument(ch)
    for obj in ch:inventory() do
        local v = obj:vnum_get()
        if v == 8802 or v == 8807 then return obj end
    end
end

local function execute(ctx)
    local ch   = ctx.ch
    local toks = ctx.argparams.tokens
    local arg1 = string.lower(toks[1] or "")
    local arg2 = string.lower(toks[2] or "")

    if not ch:know_skill("mystic music") then
        ch:send_line("You do not know how to play mystical music.")
        return
    end

    local instr = find_instrument(ch)
    if not instr then
        ch:send_line("You do not have an instrument.")
        return
    end
    local instr_vnum = instr:vnum_get()

    if ch:condition_has("mystic_melody") then
        ch:send_line("@cYou stop playing your ocarina.@n")
        ch:act_around("@c$n stops playing their ocarina.@n")
        ch:condition_remove("mystic_melody", "stopped")
        return
    end

    local skill = ch:skill_get("mystic music")

    if arg1 == "" then
        local known = "@YSongs Known\n@c-------------------@n\r\nSong of Safety\r\n"
        if skill > 50  then known = "Shadow Stitch Minuet\r\n" .. known end
        if skill > 80  then known = "Melody of Teleportation\r\n" .. known end
        if skill > 99  then known = "Song of Shielding\r\n" .. known end
        ch:send(known)
        ch:send_line("@wSyntax: song (shielding | safety | teleport | shadow )")
        return
    end

    local song_id, cost_mult

    if string.sub("safety", 1, #arg1) == arg1 then
        song_id = 1; cost_mult = 3
    elseif string.sub("shadow", 1, #arg1) == arg1 then
        if skill <= 49 then
            ch:send_line("You do not posess the skill to play such a song!")
            return
        end
        song_id = 3; cost_mult = 8
    elseif string.sub("shielding", 1, #arg1) == arg1 then
        if skill <= 98 then
            ch:send_line("You do not posess the skill to play such a song!")
            return
        end
        song_id = 2; cost_mult = 20
    elseif string.sub("teleport", 1, #arg1) == arg1 then
        if skill <= 79 then
            ch:send_line("You do not posess the skill to play such a song!")
            return
        end
        if ch:aff_flagged(dbat.consts.aff_flags.SPIRIT) then
            ch:send_line("Not while you're dead!")
            return
        end
        if arg2 == "" then
            ch:send_line("Where would you like to teleport to?\nSyntax: song teleport (earth | vegeta | kanassa | arlia | aether | namek | konack | frigid)")
            return
        end
        song_id = TELEPORT_PLANETS[arg2]
        if not song_id then
            ch:send_line("Syntax: song teleport (earth | vegeta | namek | aether | konack | kanassa | arlia | frigid)")
            return
        end
        cost_mult = 50
    else
        ch:send_line("@wSyntax: song (shielding | safety | teleport | shadow )")
        return
    end

    local cost = math.floor(ch:meter_max("ki") * 0.01 * cost_mult)
    if instr_vnum == 8802 then
        cost = math.floor(cost * 0.5)
    end

    if ch:meter_current("ki") < cost then
        ch:send_line("@wYou do not have enough ki to power the instrument for that song!@n")
        return
    end

    if song_id == 1 then
        ch:send_line("@CYou begin to play the Song of Safety! Your fingers lightly glide over the ocarina and as you blow into it sweet music similar to a lullaby issues forth from the intrument.@n")
        ch:act_around("@c$n@C begins to play a song on $s ocarina. The music seems to be some sort of lullaby.@n")
    elseif song_id == 3 then
        ch:send_line("@CYou begin to play the Shadow Stitch Minuet! Your fingers lightly glide over the ocarina and as you blow into it forboding low toned music issues forth.@n")
        ch:act_around("@c$n@C begins to play a song on $s ocarina. Depressing low toned music issues forth from the ocarina.@n")
    elseif song_id == 2 then
        ch:send_line("@CYou begin to play the Song of Shielding! Your fingers lightly glide over the ocarina and as you blow into it a triumphant series of notes issues forth.@n")
        ch:act_around("@c$n@C begins to play a song on $s ocarina. A triumphant song full of soaring sounds from the ocarina as it is played.@n")
    else
        -- teleport songs
        ch:send_line("@CYou begin to play the Melody of Teleportation! Your fingers lightly glide over the ocarina and as you blow into it a repeating light hearted melody issues forth.@n")
        ch:act_around("@c$n@C begins to play a song on $s ocarina. A light hearted melody can be heard sounding from the ocarina as it is played.@n")
    end

    ch:meter_mod_int("ki", -cost)
    ch:condition_apply_number("mystic_melody", "song", song_id, "player", "song_command")
end

return { id = "song", aliases = { { "song", 3 } }, execute = execute }
