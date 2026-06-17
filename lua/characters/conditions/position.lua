local POS_DEAD = 0
local POS_MORTALLYW = 1
local POS_INCAP = 2
local POS_STUNNED = 3
local POS_SLEEPING = 4
local POS_RESTING = 5
local POS_SITTING = 6
local POS_FIGHTING = 7
local POS_STANDING = 8

local position_mult = {
    [POS_DEAD] = 0,
    [POS_MORTALLYW] = 0,
    [POS_INCAP] = 0,
    [POS_STUNNED] = 0,
    [POS_SLEEPING] = 20000,
    [POS_RESTING] = 15000,
    [POS_SITTING] = 12500,
    [POS_FIGHTING] = -7500,
    [POS_STANDING] = 0,
}

return {
    id = "position",
    name = "Position",
    persistent = true,
    modifiers = function(ch)
        local pos = ch:condition_number_get("position", "state") or POS_STANDING
        local mult = position_mult[pos]

        local mods = {}

        if mult ~= 0 then
            mods[#mods + 1] = { target = { "regen", "vitals" }, kind = "multiplier", value = mult, label = "Position" }
        end

        return mods
    end,
}
