local dbat = require("dbat")

local SKY_LOOK = { "cloudless", "cloudy", "rainy", "lit by flashes of lightning" }

local function execute(ctx)
    local ch = ctx.ch
    if not ch:is_outside() then
        ch:send_line("You have no feeling about the weather at all.")
        return
    end

    local w = dbat.weather()
    local wind = w.change >= 0
        and "you feel a warm wind from south"
        or  "your foot tells you bad weather is due"
    local sky = SKY_LOOK[w.sky + 1] or "unknown"

    ch:send_line(string.format("The sky is %s and %s.", sky, wind))

    if ch:adm_flagged(dbat.consts.admin_flags.KNOWWEATHER) then
        ch:send_line(string.format(
            "Pressure: %d (change: %d), Sky: %d (%s)",
            w.pressure, w.change, w.sky, sky))
    end
end

return { id = "weather", aliases = { { "weather", 3 } }, execute = execute }
