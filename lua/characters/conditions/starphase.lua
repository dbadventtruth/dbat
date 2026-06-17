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

local function starphase_modifiers(ch)
    local f = form(ch)
    if f == nil then return {} end

    local mult = math.floor(f.mult * 10000)
    local phase = current_phase()
    local stat_bonus = 0
    if phase == "birth" then stat_bonus = 5 end
    if phase == "life" then stat_bonus = 8 end

    local mods = {
        { target = { "derived", "powerlevel" }, kind = "flat", value = f.bonus, label = f.name },
        { target = { "derived", "ki" }, kind = "flat", value = f.bonus, label = f.name },
        { target = { "derived", "stamina" }, kind = "flat", value = f.bonus, label = f.name },
        { target = { "derived", "powerlevel" }, kind = "multiplier", value = mult, label = f.name },
        { target = { "derived", "ki" }, kind = "multiplier", value = mult, label = f.name },
        { target = { "derived", "stamina" }, kind = "multiplier", value = mult, label = f.name },
    }

    if phase ~= "death" then
        mods[# mods + 1] = { target = { "regen", "vitals" }, kind = "percent", value = 10000, label = f.name }
    else
        mods[# mods + 1] = { target = { "regen", "vitals" }, kind = "percent", value = -7500, label = f.name }
    end

    if stat_bonus > 0 then
        mods[#mods + 1] = { target = { "derived", "strength" }, kind = "flat", value = stat_bonus, label = f.name }
        mods[#mods + 1] = { target = { "derived", "speed" }, kind = "flat", value = stat_bonus, label = f.name }
    end

    return mods
end

return {
    id = "starphase",
    name = "Starphase",
    family = "starphase",
    tags = { "transformation", "starphase" },
    exclusive_tags = {},
    persistent = true,
    form = form,
    modifiers = starphase_modifiers,
}
