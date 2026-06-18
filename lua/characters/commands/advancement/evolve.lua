local dbat  = require("dbat")
local RACE  = dbat.consts.races
local fmt   = dbat.lib.text.add_commas

-- Compute the evolution point costs for each stat.
-- Mirrors the do_evolve cost formula exactly.
local function costs(ch)
    local level     = ch:stat_get("level")
    local threshold = ch:molt_threshold()
    local pl = level + math.floor(threshold * 0.65 + ch:stat_get("powerlevel") * 0.15)
    local ki = level + math.floor(threshold * 0.50 + ch:stat_get("ki")         * 0.22)
    local st = level + math.floor(threshold * 0.50 + ch:stat_get("stamina")    * 0.15)
    return pl, ki, st
end

-- Compute the random gain for upgrading a stat.
-- C's rand_number swaps args when from > to, so handle that here.
local function evolve_gain(base)
    local gain = math.floor(base * 0.01)
    if gain <= 0 then
        return math.random(1, 5)
    else
        return math.random(math.floor(gain * 0.5), gain)
    end
end

local function show_menu(ch)
    local plcost, kicost, stcost = costs(ch)
    local exp = ch:stat_get("molt_experience")
    local lines = {
        "@D-=@YConvert Evolution Points To What?@D=-@n",
        "@D-------------------------------------@n",
        string.format("@CPowerlevel  @D: @Y%s @Wpts", fmt(plcost)),
        string.format("@CKi          @D: @Y%s @Wpts", fmt(kicost)),
        string.format("@CStamina     @D: @Y%s @Wpts", fmt(stcost)),
        string.format("@D[@Y%s @Wpts currently@D]@n", fmt(exp)),
    }
    ch:send_line(table.concat(lines, "\r\n") .. "\r\n")
end

local UPGRADES = {
    pl = {
        aliases   = { "powerlevel", "pl" },
        stat      = "powerlevel",
        cost_idx  = 1,
        label     = "@RPL",
        message   = "your body has strengthened",
    },
    ki = {
        aliases   = { "ki" },
        stat      = "ki",
        cost_idx  = 2,
        label     = "@CKi",
        message   = "your spirit has strengthened",
    },
    st = {
        aliases   = { "stamina", "st" },
        stat      = "stamina",
        cost_idx  = 3,
        label     = "@GST",
        message   = "your body has more stamina",
    },
}

-- Build a quick lookup table from alias → upgrade entry
local ALIAS_MAP = {}
for _, entry in pairs(UPGRADES) do
    for _, alias in ipairs(entry.aliases) do
        ALIAS_MAP[alias] = entry
    end
end

local function can_execute(ch)
    if ch:race_get() ~= "arlian" then
        return false, "Only Arlians can evolve!"
    end
    if ch:is_npc() then
        return false, "NPCs cannot evolve!"
    end
    return true
end

local function execute(ctx)
    local ch = ctx.ch

    local arg = (ctx.argparams.tokens[1] or ""):lower()

    if arg == "" then
        show_menu(ch)
        return
    end

    local entry = ALIAS_MAP[arg]
    if not entry then
        ch:send_line("Evolve what? Try @Cpowerlevel@n, @Cki@n, or @Cstamina@n.")
        return
    end

    local plcost, kicost, stcost = costs(ch)
    local cost_values = { plcost, kicost, stcost }
    local cost      = cost_values[entry.cost_idx]
    local threshold = ch:molt_threshold()
    local exp       = ch:stat_get("molt_experience")

    if cost > threshold then
        ch:send_line(string.format(
            "You need a few more evolution levels before you can start upgrading %s.",
            entry.stat))
        return
    end

    if exp < cost then
        ch:send_line("You do not have enough evolution experience.")
        return
    end

    local gain = evolve_gain(ch:stat_get(entry.stat))
    ch:stat_mod(entry.stat, gain)
    ch:stat_mod("molt_experience", -cost)

    ch:send_line(string.format(
        "Your body evolves to make better use of the way it is now, and you feel that %s. @D[%s@D: @Y+%s@D]@n",
        entry.message, entry.label, fmt(gain)))
end

return {
    id      = "evolve",
    aliases = { { "evolve", 5 } },
    execute = execute,
    can_execute = can_execute,
}
