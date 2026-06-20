local dbat = require("dbat")
local PLR   = dbat.consts.player_flags

local function execute(ctx)
    local ch = ctx.ch
    if not ch:player_flagged(PLR.TAILHIDE) then
        ch:player_flag_set(PLR.TAILHIDE, true)
        ch:send_line("You tuck your tail away, hiding it from view.")
        ch:act_around("$n tucks $s tail away, hiding it from view.")
    else
        ch:player_flag_set(PLR.TAILHIDE, false)
        ch:send_line("You have decided to display your tail for all to see!")
        ch:act_around("$n has decided to display $s tail for all to see!")
    end
end

local function can_execute(ch)
    local race = ch:race_get()
    if race ~= "saiyan" and race ~= "halfbreed" then
        return false, "You have no need to hide your tail!"
    end
    return true
end

return { id = "tailhide", aliases = { { "tailhide", 5 } }, execute = execute, can_execute = can_execute }
