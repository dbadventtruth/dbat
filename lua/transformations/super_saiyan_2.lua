local RACE_SAIYAN = 1
local RACE_HALFBREED = 7
local PLR_LSSJ = 68

local self_msg = "@WBlinding rage burns through your mind as a sudden eruption of energy surges forth! A golden aura bursts up around your body, glowing as bright as the sun. Rushing winds rocket out from your body in every direction as bolts of electricity begin to crackle in your aura. As your aura dims you are left standing confidently, having achieved @CSuper @YSaiyan @GSecond@W!@n"
local others_msg = "@C$n@W stands up straight with $s head back as $e releases an ear piercing scream! A blindingly bright golden aura bursts up around $s body, glowing as bright as the sun. As rushing winds begin to rocket out from $m in every direction, bolts of electricity flash and crackle in $s aura. As $s aura begins to dim $e is left standing confidently, having achieved @CSuper @YSaiyan @GSecond@W!@n"
local legendary_self_msg = "@WYou roar and then stand at your full height. You flex every muscle in your body as you feel your strength grow! Your eyes begin to glow @wwhite@W with energy, your hair turns @Ygold@W, and at the same time a @wbright @Yg@yo@Yl@yd@Ye@yn@W aura flashes up around your body! You release your @YL@ye@Dg@We@wn@Yd@ya@Dr@Yy@W power upon the universe!@n"
local legendary_others_msg = "@C$n @Wroars and then stands at $s full height. Then $s muscles start to buldge and grow as $e flexes them! Suddenly $s eyes begin to glow @wwhite@W with energy, $s hair turns @Ygold@W, and at the same time a @wbright @Yg@yo@Yl@yd@Ye@yn@W aura flashes up around $s body! @C$n@W releases $s @YL@ye@Dg@We@wn@Yd@ya@Dr@Yy@W power upon the universe!@n"

local function form(ch)
    local race = ch:race_get()
    if race == RACE_HALFBREED then
        return { bonus = 16500000, mult = 4.0, drain = 0.2, requires_pl = 55000000, name = "@YSuper @CSaiyan @WSecond@n", self_msg = self_msg, others_msg = others_msg }
    end
    if race == RACE_SAIYAN then
        if ch:player_flagged(PLR_LSSJ) then
            return { bonus = 185000000, mult = 5.25, drain = 0.2, requires_pl = 250000000, name = "@YLegendary @CSuper Saiyan@n", self_msg = legendary_self_msg, others_msg = legendary_others_msg }
        end
        return { bonus = 20000000, mult = 3.0, drain = 0.2, requires_pl = 55000000, name = "@YSuper @CSaiyan @WSecond@n", self_msg = self_msg, others_msg = others_msg }
    end
    return nil
end

return {
    id = "super_saiyan_2",
    name = "Super Saiyan Second",
    family = "super_saiyan",
    tier = 2,
    condition = "super_saiyan_2",
    rpp_cost = 0,
    form = form,
    available = function(ch) return form(ch) ~= nil end,
    display_name = function(ch) local f = form(ch); return f and f.name or "Super Saiyan Second" end,
    requires_pl = function(ch) local f = form(ch); return f and f.requires_pl or 0 end,
    bonus = function(ch) local f = form(ch); return f and f.bonus or 0 end,
    mult = function(ch) local f = form(ch); return f and f.mult or 1.0 end,
    drain = function(ch) local f = form(ch); return f and f.drain or 0.0 end,
    msg_transform_self = function(ch) local f = form(ch); return f and f.self_msg or self_msg end,
    msg_transform_others = function(ch) local f = form(ch); return f and f.others_msg or others_msg end,
}
