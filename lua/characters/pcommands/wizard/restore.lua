local dbat = require("dbat")

local function find_player_world(name)
    local found = nil
    local lower = string.lower(name)
    dbat.each_player(function(ch)
        if found then return end
        local n = string.lower(ch:name_get() or "")
        if string.sub(n, 1, #lower) == lower then
            found = ch
        end
    end)
    return found
end

local function execute(ctx)
    local ch  = ctx.ch
    local arg = ctx.argparams.tokens[1] or ""

    if arg == "" then
        ch:send_line("Whom do you wish to restore?")
        return
    end

    if string.sub("all", 1, #arg) == string.lower(arg) and #arg >= 2 then
        local msg = string.format("[Log: %s restored all.]", ch:name_get())
        dbat.send_to_imm(msg)
        dbat.log_imm_action(string.format("RESTORE: %s has restored all players.", ch:name_get()))
        dbat.each_player(function(vict)
            ch:restore(vict)
        end)
        ch:send_line("Okay.")
        return
    end

    local vict = find_player_world(arg)
    if not vict then
        ch:send_line("There is no one by that name in the world.")
        return
    end
    if not vict:is_npc() and not ch:id_get() == vict:id_get()
       and vict:admin_level_get() >= ch:admin_level_get()
    then
        ch:send_line("They don't need your help.")
        return
    end

    ch:restore(vict)
    ch:send_line("Done.")
    dbat.send_to_imm(string.format("[Log: %s restored %s.]", ch:name_get(), vict:name_get()))
    dbat.log_imm_action(string.format("RESTORE: %s has restored %s.", ch:name_get(), vict:name_get()))
end

return { id = "restore", aliases = { { "restore", 3 } }, execute = execute }
