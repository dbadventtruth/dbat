local dbat = require("dbat")
local act  = dbat.lib.act
local CARD = dbat.consts.item_extra_flags.ANTI_HIEROPHANT

local function execute(ctx)
    local ch  = ctx.ch
    local arg = (ctx.argparams.tokens[1] or ""):lower()

    if arg ~= "look" and arg ~= "show" then
        ch:send_line("Syntax: hand (look | show)")
        return
    end

    local count = 0

    if arg == "look" then
        ch:send_line("@CYour hand contains:\r\n@D---------------------------@n")
        for obj in ch:inventory() do
            if obj:extra_flagged(CARD) then
                count = count + 1
                ch:send_line("%s", obj:short_description_get())
            end
        end
        act.around(ch, "$n looks at $s hand.")
        if count == 0 then
            ch:send("No cards.")
            act.around(ch, "There were no cards.")
        elseif count > 7 then
            act.to_char(ch, "You have more than seven cards in your hand.")
            act.around(ch, "$n has more than seven cards in $s hand.")
        else
            act.around(ch, string.format("There are %d cards in the hand.", count))
        end

    elseif arg == "show" then
        ch:send_line("You show off your hand to the room.")
        act.around(ch, "@C$n's hand contains:\r\n@D---------------------------@n")
        for obj in ch:inventory() do
            if obj:extra_flagged(CARD) then
                count = count + 1
                act.around(ch, "$p", { object = obj })
            end
        end
        if count == 0 then
            act.around(ch, "No cards.")
        end
        if count > 7 then
            act.to_char(ch, "You have more than seven cards in your hand.")
            act.around(ch, "$n has more than seven cards in $s hand.")
        end
    end
end

return { id = "hand", aliases = { { "hand", 3 } }, execute = execute }
