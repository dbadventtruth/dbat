local RACE_SAIYAN = 1
local PLR_LSSJ = 68

local self_msg = "@WHaving absorbed enough blutz waves, your body begins to transform! Red fur grows over certain parts of your skin as your hair grows longer and unkempt. A red outline forms around your eyes while the irises of those very same eyes change to an amber color. Energy crackles about your body violently as you achieve the peak of saiyan perfection, @CSuper @YSaiyan @GFourth@W!@n"
local others_msg = "@WHaving absorbed enough blutz waves, @C$n@W's body begins to transform! Red fur grows over certain parts of $s skin as $s hair grows longer and unkempt. A red outline forms around $s eyes while the irises of those very same eyes change to an amber color. Energy crackles about $s body violently as $e achieves the peak of saiyan perfection, @CSuper @YSaiyan @GFourth@W!@n"

local function form(ch)
    if ch:race_get() ~= RACE_SAIYAN or ch:player_flagged(PLR_LSSJ) then return nil end
    return { bonus = 200000000, mult = 5.0, drain = 0.2, requires_pl = 1625000000, name = "@YSuper @CSaiyan @WFourth@n" }
end

return {
    id = "super_saiyan_4",
    name = "Super Saiyan Fourth",
    family = "super_saiyan",
    tier = 4,
    condition = "super_saiyan_4",
    rpp_cost = 0,
    form = form,
    available = function(ch) return form(ch) ~= nil end,
    display_name = function(ch) local f = form(ch); return f and f.name or "Super Saiyan Fourth" end,
    requires_pl = function(ch) local f = form(ch); return f and f.requires_pl or 0 end,
    bonus = function(ch) local f = form(ch); return f and f.bonus or 0 end,
    mult = function(ch) local f = form(ch); return f and f.mult or 1.0 end,
    drain = function(ch) local f = form(ch); return f and f.drain or 0.0 end,
    msg_transform_self = self_msg,
    msg_transform_others = others_msg,
}
