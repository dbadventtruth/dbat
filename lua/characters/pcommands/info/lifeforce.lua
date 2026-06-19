local function execute(ctx)
    local ch  = ctx.ch
    local arg = ctx.argparams.tokens[1] or ""

    if arg == "" then
        ch:send_line("Syntax: life (0 - 99)\n0 is off.")
        return
    end

    local setting = math.tointeger(tonumber(arg) or -999)
    if not setting then
        ch:send_line(string.format("Syntax: life (1 - 99)\n%s isn't an acceptable percent.", arg))
        return
    end

    if setting > 99 then
        ch:send_line(string.format("Syntax: life (1 - 99)\n%d isn't an acceptable percent.", setting))
        return
    elseif setting <= 0 then
        ch:send_line("Your will just isn't in the fight, huh?\nYou will not use up life force to maintain your PL period.")
        ch:stat_set("life_percent", 0)
    else
        ch:send_line(string.format("Your life force will automatically kick in at %d%% of your optimal PL.", setting))
        ch:stat_set("life_percent", setting)
    end
end

return { id = "lifeforce", aliases = { { "life", 2 } }, execute = execute }
