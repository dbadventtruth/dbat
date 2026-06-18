local _dbat
local function C() if not _dbat then _dbat = require("dbat") end return _dbat end

return {
    id = "fishing",
    name = "Fishing",
    tags = { "fishing" },
    persistent = false,
    status_line = function(ch, cond)
        local bonus = ch:legacy_modifier(C().consts.applies.ACCURACY, -1)
        return string.format("Current Fishing Pole Bonus @D[@C%d@D]@n", bonus)
    end,
}
