local dbat = require("dbat")
local PLR = dbat.consts.player_flags

local function on_tick(ch, cond)
    local ki_regen = ch:der_total("ki_regen")
    local cost = ki_regen + math.floor(ch:meter_max("ki") * 0.05)
    if ch:meter_current("ki") > cost then
        ch:send_line("You send more energy into your aura to keep the light active.")
        ch:meter_mod("ki", -cost)
    else
        ch:send_line("You don't have enough energy to keep the aura active.")
        ch:act_around("$n's aura slowly stops shining and fades.")
        ch:condition_remove("auralight", "ki_depleted")
    end
end

return {
    id = "auralight",
    name = "Aura Light",
    persistent = false,
    on_apply = function(ch, cond)
        ch:player_flag_set(PLR.AURALIGHT, true)
        local room = ch:room()
        if room then room:light_mod(1) end
        ch:reveal_hiding(0)
        cond:schedule_event("tick", 100000, 100000)
    end,
    on_game_activate = function(ch, cond)
        if not cond:event_pending("tick") then
            cond:schedule_event("tick", 100000, 100000)
        end
    end,
    on_remove = function(ch, cond)
        cond:cancel_event("tick")
        ch:player_flag_set(PLR.AURALIGHT, false)
        local room = ch:room()
        if room then room:light_mod(-1) end
    end,
    on_event = function(ch, cond, event)
        if event == "tick" then on_tick(ch, cond) end
    end,
}
