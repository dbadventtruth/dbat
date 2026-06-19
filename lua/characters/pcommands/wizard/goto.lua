local dbat = require("dbat")
local PLR  = dbat.consts.player_flags
local act  = dbat.lib.act

local function execute(ctx)
    local ch  = ctx.ch
    local arg = ctx.argparams.raw

    if arg == "" then
        ch:send_line("Usage: goto <room vnum | player name>")
        return
    end

    local room = ch:find_target_room(arg)
    if not room then return end

    if ch:player_flagged(PLR.HEALT) then
        ch:send_line("They are inside a healing tank!")
        return
    end

    local poofout = ch:poofout_get()
    local msg_out = "$n " .. (poofout or "disappears in a puff of smoke.")
    act.around(ch, msg_out, { actor = ch })

    ch:from_room()
    ch:to_room(room)

    local poofin = ch:poofin_get()
    local msg_in = "$n " .. (poofin or "appears with an ear-splitting bang.")
    act.around(ch, msg_in, { actor = ch })

    ch:look_at_room()
    dbat.dgscripts.enter_wtrigger(ch:room_get(), ch, -1)
end

return { id = "goto", aliases = { { "goto", 2 } }, execute = execute }
