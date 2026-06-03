local RACE_SAIYAN = 1
local RACE_HALFBREED = 7
local PLR_LSSJ = 68

local self_msg = "@WSomething inside your mind snaps as your rage spills over! Lightning begins to strike the ground all around you as you feel torrents of power rushing through every fiber of your being. Your hair suddenly turns golden as your eyes change to the color of emeralds. In a final rush of power a golden aura rushes up around your body! You have become a @CSuper @YSaiyan@W!@n"
local others_msg = "@C$n@W screams in rage as lightning begins to crash all around! $s hair turns golden and $s eyes change to an emerald color as a bright golden aura bursts up around $s body! As $s energy stabilizes $e wears a fierce look upon $s face, having transformed into a @CSuper @YSaiyan@W!@n"

local function form(ch)
    local race = ch:race_get()
    if race == RACE_HALFBREED then
        return { bonus = 900000, mult = 2.0, drain = 0.1, requires_pl = 1400000, name = "@YSuper @CSaiyan @WFirst@n" }
    end
    if race == RACE_SAIYAN then
        if ch:player_flagged(PLR_LSSJ) then
            return { bonus = 800000, mult = 2.0, drain = 0.1, requires_pl = 500000, name = "@YSuper @CSaiyan @WFirst@n" }
        end
        return { bonus = 800000, mult = 2.0, drain = 0.1, requires_pl = 1200000, name = "@YSuper @CSaiyan @WFirst@n" }
    end
    return nil
end

return {
    id = "super_saiyan_1",
    name = "Super Saiyan First",
    alias = { "ssj", "ssj1", "super saiyan", "super saiyan 1", "super saiyan first" },
    sort_order = 101,
    family = "super_saiyan",
    tier = 1,
    condition = "super_saiyan_1",
    rpp_cost = 0,
    form = form,
    available = function(ch) return form(ch) ~= nil end,
    display_name = function(ch) local f = form(ch); return f and f.name or "Super Saiyan First" end,
    requires_pl = function(ch) local f = form(ch); return f and f.requires_pl or 0 end,
    bonus = function(ch) local f = form(ch); return f and f.bonus or 0 end,
    mult = function(ch) local f = form(ch); return f and f.mult or 1.0 end,
    drain = function(ch) local f = form(ch); return f and f.drain or 0.0 end,
    msg_transform_self = self_msg,
    msg_transform_others = others_msg,
}
