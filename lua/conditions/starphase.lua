local transform = require("lua.transform_condition")

local function current_phase()
    local time = require("dbat").time()
    if time.day <= 15 then return "birth" end
    if time.day <= 22 then return "life" end
    return "death"
end

local function form(ch)
    local phase = current_phase()
    if phase == "birth" then
        return { name = "@CBirth Phase@n", bonus = math.floor(ch:stat_get("powerlevel") * 0.4), mult = 2.0, drain = 0.0, requires_pl = 0 }
    end
    if phase == "life" then
        return { name = "@GLife Phase@n", bonus = math.floor(ch:stat_get("powerlevel") * 0.8), mult = 3.0, drain = 0.0, requires_pl = 0 }
    end
    return nil
end

return transform.condition({
    id = "starphase",
    name = "Starphase",
    family = "starphase",
    tags = { "transformation", "starphase" },
    exclusive_tags = {},
    persistent = true,
    form = form,
})
