local RACE_SAIYAN = 1

local self_msg = "@WElectricity begins to crackle around your body as your aura grows explosively! You yell as your powerlevel begins to skyrocket while your hair grows to multiple times the length it was previously. Your muscles become incredibly dense instead of growing in size, preserving your speed. Finally your irises appear just as your transformation becomes complete, having achieved @CSuper @YSaiyan @GThird@W!@n"
local others_msg = "@WElectricity begins to crackle around @C$n@W, as $s aura grows explosively! $e yells as the energy around $m skyrockets and $s hair grows to multiple times its previous length. $e smiles as $s irises appear and $s muscles tighten up. $s transformation complete, $e now stands confidently, having achieved @CSuper @YSaiyan @GThird@W!@n"

local function form(ch)
    if ch:race_get() ~= RACE_SAIYAN then return nil end
    return { bonus = 80000000, mult = 4.0, drain = 0.2, requires_pl = 200000000, name = "@YSuper @CSaiyan @WThird@n" }
end

return {
    id = "super_saiyan_3",
    name = "Super Saiyan Third",
    alias = { "ssj3", "super saiyan 3", "super saiyan third" },
    sort_order = 103,
    family = "super_saiyan",
    tier = 3,
    condition = "super_saiyan_3",
    rpp_cost = 0,
    form = form,
    available = function(ch) return form(ch) ~= nil end,
    display_name = function(ch) local f = form(ch); return f and f.name or "Super Saiyan Third" end,
    requires_pl = function(ch) local f = form(ch); return f and f.requires_pl or 0 end,
    bonus = function(ch) local f = form(ch); return f and f.bonus or 0 end,
    mult = function(ch) local f = form(ch); return f and f.mult or 1.0 end,
    drain = function(ch) local f = form(ch); return f and f.drain or 0.0 end,
    msg_transform_self = self_msg,
    msg_transform_others = others_msg,
}
