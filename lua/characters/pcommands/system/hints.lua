local hints = {}

hints.id = "hints"
hints.priority = 0
hints.aliases = {{"hints", 4}}
hints.tags = { "system" }

function hints.can_execute(ch)
    if ch:is_npc() then
        return false, "NPCs don't need hints."
    end
    return true
end

function hints.execute(ctx)
    local dbat = require("dbat")

    local ch = ctx.ch
    
    if ch:condition_has("system_hints") then
        ch:condition_remove("system_hints")
    else
        ch:condition_add("system_hints")
    end

end

return hints