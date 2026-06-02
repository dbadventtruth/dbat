local RACE_SAIYAN = 1
local PLR_LSSJ = 68

local self_msg = "@WYou roar and then stand at your full height. You flex every muscle in your body as you feel your strength grow! Your eyes begin to glow @wwhite@W with energy, your hair turns @Ygold@W, and at the same time a @wbright @Yg@yo@Yl@yd@Ye@yn@W aura flashes up around your body! You release your @YL@ye@Dg@We@wn@Yd@ya@Dr@Yy@W power upon the universe!@n"
local others_msg = "@C$n @Wroars and then stands at $s full height. Then $s muscles start to buldge and grow as $e flexes them! Suddenly $s eyes begin to glow @wwhite@W with energy, $s hair turns @Ygold@W, and at the same time a @wbright @Yg@yo@Yl@yd@Ye@yn@W aura flashes up around $s body! @C$n@W releases $s @YL@ye@Dg@We@wn@Yd@ya@Dr@Yy@W power upon the universe!@n"

local function form(ch)
    if ch:race_get() ~= RACE_SAIYAN or not ch:player_flagged(PLR_LSSJ) then return nil end
    return { bonus = 185000000, mult = 5.25, drain = 0.2, requires_pl = 250000000, name = "@YLegendary @CSuper Saiyan@n" }
end

return {
    id = "legendary_super_saiyan",
    name = "Legendary Super Saiyan",
    alias = { "lssj", "legendary", "legendary super saiyan" },
    sort_order = 105,
    family = "super_saiyan",
    tier = 2,
    condition = "legendary_super_saiyan",
    rpp_cost = 0,
    form = form,
    available = function(ch) return form(ch) ~= nil end,
    display_name = function(ch) local f = form(ch); return f and f.name or "Legendary Super Saiyan" end,
    requires_pl = function(ch) local f = form(ch); return f and f.requires_pl or 0 end,
    bonus = function(ch) local f = form(ch); return f and f.bonus or 0 end,
    mult = function(ch) local f = form(ch); return f and f.mult or 1.0 end,
    drain = function(ch) local f = form(ch); return f and f.drain or 0.0 end,
    msg_transform_self = self_msg,
    msg_transform_others = others_msg,
}
