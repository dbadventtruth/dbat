local fmt = require("dbat").lib.text.add_commas

local function execute(ctx)
    local ch = ctx.ch
    if ch:is_npc() then
        ch:send_line("You ain't nothin' but a hound-dog.")
        return
    end
    local t = {}
    for i = 1, 100 do
        if i == 100 then
            t[#t+1] = string.format("[100] %8s          : \r\n", fmt(ch:level_exp(100)))
        else
            t[#t+1] = string.format("[%2d] %8s-%-8s : \r\n",
                i, fmt(ch:level_exp(i)), fmt(ch:level_exp(i + 1) - 1))
        end
    end
    ch:send(table.concat(t))
end

return { id = "levels", aliases = { { "levels", 3 } }, execute = execute }
