local dbat = require("dbat")

local function execute(ctx)
    local ch = ctx.ch
    if not ch:condition_has("kyodaika") then
        ch:condition_add("kyodaika", "command", "kyodaika")
    else
        ch:condition_remove("kyodaika", "command")
    end
    ch:save()
end

local function can_execute(ch)
    if ch:race_get() ~= "namek" then
        return false, "You are not a namek!"
    end
    return true
end

return { id = "kyodaika", aliases = { { "kyodaika", 7 } }, execute = execute, can_execute = can_execute }
