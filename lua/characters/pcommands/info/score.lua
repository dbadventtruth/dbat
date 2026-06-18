local dbat        = require("dbat")
local PLR         = dbat.consts.player_flags
local fmt         = dbat.lib.text.add_commas
local partial_match = require("lua.libs.utils").partial_match

local SIZE_NAMES = {
    "fine", "diminutive", "tiny", "small", "medium",
    "large", "huge", "gargantuan", "colossal",
}

local GENDER_DISPLAY = { neutral = "Neutral", male = "Male", female = "Female" }

local FOOTER = "  @cO@D" .. string.rep("-", 68) .. "@cO@n\n"

-- Computes the GOLD_CARRY macro: level-based gold capacity.
local function gold_carry_max(ch)
    local lv = ch:stat_get("level")
    if lv < 50 then return lv * 10000
    elseif lv < 100 then return 500000
    else return 50000000 end
end

-- ---------------------------------------------------------------------------
-- Section: Personal
-- ---------------------------------------------------------------------------
local function render_personal(ch)
    local t = {}
    t[#t+1] = "  @cO@D-----------------------------[  @cPersonal  @D]-----------------------------@cO@n\n"
    t[#t+1] = string.format(
        "  @D|  @CName@D: @W%15s@D,   @CTitle@D: @W%-38s@D|@n\n",
        ch:name_get(), ch:title_get())

    if ch:race_get() == "android" then
        local model
        if     ch:player_flagged(PLR.ABSORB) then model = "@CAbsorption"
        elseif ch:player_flagged(PLR.REPAIR) then model = "@GSelf Repairing"
        elseif ch:player_flagged(PLR.SENSEM) then model = "@RSensor Equiped"
        else model = "Unknown" end
        t[#t+1] = string.format(
            "  @D| @CModel@D: %15s@D,    @CUGP@D: @G%15s@D,  @CVersion@D: @r%-12s@D|@n\n",
            model, fmt(ch:stat_get("upgrades")), "???")
    end

    local clan = ch:clan_get()
    if clan then
        t[#t+1] = string.format("  @D|  @CClan@D: @W%-64s@D|@n\n", clan)
    end

    local race_def   = dbat.get("races",   ch:race_get())
    local sensei_def = dbat.get("senseis", ch:sensei_get())
    local race_name   = race_def   and race_def.name    or ch:race_get()
    local sensei_name = sensei_def and sensei_def.name  or ch:sensei_get()
    local sensei_art  = sensei_def and sensei_def.style or ""
    t[#t+1] = string.format(
        "  @D|  @CRace@D: @W%10s@D,  @CSensei@D: @W%15s@D,     @CArt@D: @W%-17s@D|@n\n",
        race_name, sensei_name, sensei_art)

    t[#t+1] = string.format(
        "  @D|   @CAge@D: @W%10s@D,  @CHeight@D: @W%15s@D,  @CWeight@D: @W%-17s@D|@n\n",
        fmt(ch:age_years()),
        ch:height_cm() .. "cm",
        ch:weight_kg() .. "kg")

    local size_str   = SIZE_NAMES[ch:size_get() + 1] or "unknown"
    local gender_str = GENDER_DISPLAY[ch:sex_get()] or "Neutral"
    t[#t+1] = string.format(
        "  @D|@CGender@D: @W%10s@D,  @C  Size@D: @W%15s@D,  @C Align@D: @W%-17s@D|@n\n",
        gender_str, size_str, ch:align_str())

    return table.concat(t)
end

-- ---------------------------------------------------------------------------
-- Section: Health
-- ---------------------------------------------------------------------------
local function render_health(ch)
    local t = {}
    t[#t+1] = "  @cO@D-----------------------------@D[   @cHealth   @D]-----------------------------@cO@n\n"
    t[#t+1] = "                 @D<@rPowerlevel@D>          <@BKi@D>              <@GStamina@D>@n\n"
    t[#t+1] = string.format(
        "    @wCurrent   @D-[@R%-16s@D]-[@R%-16s@D]-[@R%-16s@D]@n\n",
        fmt(ch:meter_current("powerlevel")),
        fmt(ch:meter_current("ki")),
        fmt(ch:meter_current("stamina")))
    t[#t+1] = string.format(
        "    @wMaximum   @D-[@r%-16s@D]-[@r%-16s@D]-[@r%-16s@D]@n\n",
        fmt(ch:meter_max("powerlevel")),
        fmt(ch:meter_max("ki")),
        fmt(ch:meter_max("stamina")))
    t[#t+1] = string.format(
        "    @wBase      @D-[@m%-16s@D]-[@m%-16s@D]-[@m%-16s@D]@n\n",
        fmt(ch:stat_get("powerlevel")),
        fmt(ch:stat_get("ki")),
        fmt(ch:stat_get("stamina")))

    if ch:race_get() ~= "android" then
        local lf_cur = ch:meter_current("lifeforce")
        local lf_max = ch:meter_max("lifeforce")
        t[#t+1] = string.format(
            "    @wLife Force@D-[@C%16s@D/@c%16s@D]- @wLife Percent@D-[@Y%3d%s@D]@n\n",
            fmt(lf_cur > 0 and lf_cur or 0), fmt(lf_max),
            ch:stat_get("life_percent"), "%")
    end

    return table.concat(t)
end

-- ---------------------------------------------------------------------------
-- Section: Statistics
-- ---------------------------------------------------------------------------
local function render_statistics(ch)
    local t = {}
    t[#t+1] = "  @cO@D-----------------------------@D[ @cStatistics @D]-----------------------------@cO@n\n"
    t[#t+1] = string.format(
        "      @D<@wCharacter Level@D: @w%-3d@D> <@wRPP@D: @w%-3d@D>\n",
        ch:stat_get("level"), ch:rp_get())
    t[#t+1] = string.format(
        "      @D<@wSpeed Index@D: @w%-15s@D> <@wArmor Index@D: @w%-15s@D>@n\n",
        fmt(ch:der_total("speed_index")), fmt(ch:der_total("armor")))
    t[#t+1] = string.format(
        "    @D[    @RStrength@D|@G%2d (%3d)@D] [     @YAgility@D|@G%2d (%3d)@D] [      @BSpeed@D|@G%2d (%3d)@D]@n\n",
        ch:stat_get("strength"),  ch:der_total("strength"),
        ch:stat_get("agility"),   ch:der_total("agility"),
        ch:stat_get("speed"),     ch:der_total("speed"))
    t[#t+1] = string.format(
        "    @D[@gConstitution@D|@G%2d (%3d)@D] [@CIntelligence@D|@G%2d (%3d)@D] [     @MWisdom@D|@G%2d (%3d)@D]@n\n",
        ch:stat_get("constitution"),  ch:der_total("constitution"),
        ch:stat_get("intelligence"),  ch:der_total("intelligence"),
        ch:stat_get("wisdom"),        ch:der_total("wisdom"))

    return table.concat(t)
end

-- ---------------------------------------------------------------------------
-- Section: Other
-- ---------------------------------------------------------------------------
local function render_other(ch)
    local t = {}
    t[#t+1] = "  @cO@D-----------------------------@D[   @cOther    @D]-----------------------------@cO@n\n"
    t[#t+1] = "                @D<@YZenni@D>                 <@rInventory Weight@D>@n\n"
    t[#t+1] = string.format(
        "      @D[   @CCarried@D| @W%-15s@D] [   @CCarried@D| @W%-15s@D]@n\n",
        fmt(ch:stat_get("money")), fmt(ch:der_total("weight_carried")))
    t[#t+1] = string.format(
        "      @D[      @CBank@D| @W%-15s@D] [ @CMax Carry@D| @W%-15s@D]@n\n",
        fmt(ch:stat_get("money_bank")), fmt(ch:der_total("weight_carry_capacity")))
    t[#t+1] = string.format(
        "      @D[ @CMax Carry@D| @W%-15s@D]@n\n",
        fmt(gold_carry_max(ch)))
    t[#t+1] = string.format(
        "      @D[  @CInterest@D| @W%-15s@D]\n",
        fmt(ch:der_total("bank_interest")))

    if ch:race_get() == "arlian" then
        t[#t+1] = "                             @D<@GEvolution @D>@n\n"
        t[#t+1] = string.format(
            "      @D[ @CEvo Level@D| @W%-15d@D] [   @CEvo Exp@D| @W%-15s@D]\n",
            ch:stat_get("molt_level"), fmt(ch:stat_get("molt_experience")))
        t[#t+1] = string.format(
            "      @D[ @CThreshold@D| @W%-15s@D]@n\n",
            fmt(ch:molt_threshold()))
    end

    local level = ch:stat_get("level")
    if level < 100 then
        t[#t+1] = "                             @D<@gAdvancement@D>@n\n"
        local exp       = ch:stat_get("experience")
        local exp_next  = ch:level_exp(level + 1)
        t[#t+1] = string.format(
            "      @D[@CExperience@D| @W%-15s@D] [@CNext Level@D| @W%-15s@D]@n\n",
            fmt(exp), fmt(exp_next - exp))
        t[#t+1] = string.format(
            "      @D[  @CRpp Cost@D| @W%-15d@D]@n\n",
            ch:rpp_to_level())
    end

    local played = ch:time_played()
    t[#t+1] = string.format(
        "\n     @D<@wPlayed@D: @yYears @D(@W%2d@D) @yWeeks @D(@W%2d@D) @yDays @D(@W%2d@D) @yHours @D(@W%2d@D) @yMinutes @D(@W%2d@D)>@n\n",
        math.floor(played / 31536000),
        math.floor((played % 31536000) / 604800),
        math.floor((played % 604800)   / 86400),
        math.floor((played % 86400)    / 3600),
        math.floor((played % 3600)     / 60))

    return table.concat(t)
end

-- ---------------------------------------------------------------------------
-- Top-level render function (future: takes viewer, target, mode)
-- ---------------------------------------------------------------------------
local function render(ch, mode)
    local t = {}
    if not mode or mode == "full" then
        t[#t+1] = render_personal(ch)
        t[#t+1] = render_health(ch)
        t[#t+1] = render_statistics(ch)
        t[#t+1] = render_other(ch)
    elseif mode == "personal"   then t[#t+1] = render_personal(ch)
    elseif mode == "health"     then t[#t+1] = render_health(ch)
    elseif mode == "statistics" then t[#t+1] = render_statistics(ch)
    elseif mode == "other"      then t[#t+1] = render_other(ch)
    end
    t[#t+1] = FOOTER
    return table.concat(t)
end

local MODES = { "personal", "health", "statistics", "other" }

return {
    id      = "score",
    aliases = {{"score", 2}},
    can_execute = function(ch)
        if ch:is_npc() then return false, "NPCs don't have a score." end
        return true
    end,
    execute = function(ctx)
        local ch  = ctx.ch
        local arg = ctx.argparams.tokens[1]
        if arg then
            local mode = partial_match(MODES, arg)
            if not mode then
                ch:send_line("Syntax: score, or... score (personal, health, statistics, other)")
                return
            end
            ch:send(render(ch, mode))
        else
            ch:send(render(ch, nil))
        end
    end,
}
