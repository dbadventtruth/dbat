local dbat = require("dbat")

local WEEKDAYS = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
local MONTHS   = {
    "Month of January", "Month of February", "Month of March",
    "Month of April",   "Month of May",       "Month of June",
    "Month of July",    "Month of August",    "Month of September",
    "Month of October", "Month of November",  "Month of December",
}

local function ordinal_suffix(n)
    if (n % 100) // 10 == 1 then return "th" end
    local r = n % 10
    if r == 1 then return "st" end
    if r == 2 then return "nd" end
    if r == 3 then return "rd" end
    return "th"
end

local function execute(ctx)
    local ch  = ctx.ch
    local t   = dbat.time()

    local hour12 = t.hours % 12
    if hour12 == 0 then hour12 = 12 end
    local ampm    = t.hours >= 12 and "PM" or "AM"
    local day     = t.day + 1
    local weekday = WEEKDAYS[(day % 6) + 1] or "Unknown"
    local suf     = ordinal_suffix(day)
    local month   = MONTHS[(t.month % 12) + 1] or "Unknown"

    ch:send_line(string.format("It is %d o'clock %s, on %s.", hour12, ampm, weekday))
    ch:send_line(string.format("The %d%s Day of the %s, Year %d.", day, suf, month, t.year))
end

return { id = "time", aliases = { { "time", 2 } }, execute = execute }
