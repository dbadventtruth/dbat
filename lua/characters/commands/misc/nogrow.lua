local dbat = require("dbat")
local PLR   = dbat.consts.player_flags

local function execute(ctx)
    local ch = ctx.ch
    if not ch:player_flagged(PLR.NOGROW) then
        ch:player_flag_set(PLR.NOGROW, true)
        ch:send_line("You have decided to halt your tail growth!")
    else
        ch:player_flag_set(PLR.NOGROW, false)
        ch:send_line("You have decided to regrow your tail!")
    end
end

local function can_execute(ch)
    local race = ch:race_get()
    if race ~= "saiyan" and race ~= "halfbreed" then
        return false, "What do you mean?"
    end
    return true
end

return { id = "nogrow", aliases = { { "nogrow", 4 } }, execute = execute, can_execute = can_execute }
