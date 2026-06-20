local function on_tick(ch, cond)
    if math.random(1, 5) == 2 then
        ch:condition_remove("mental_break", "recovered")
    end
end

return {
    id         = "mental_break",
    name       = "Mental Break",
    tags       = { "mental_break" },
    persistent = false,
    legacy_affects = { dbat.consts.aff_flags.MBREAK },
    modifiers = function(ch, cond)
        return {
            { target = { "derived", "intelligence" }, kind = "percent", value = -2000, label = "Mental Break" },
            { target = { "derived", "wisdom" },       kind = "percent", value = -2000, label = "Mental Break" },
        }
    end,
    on_apply = function(ch, cond)
        cond:schedule_event("tick", 100000, 100000)
    end,
    on_game_activate = function(ch, cond)
        if not cond:event_pending("tick") then
            cond:schedule_event("tick", 100000, 100000)
        end
    end,
    on_remove = function(ch, cond)
        cond:cancel_event("tick")
        ch:send_line("@wYour mind is no longer in turmoil, you can charge ki again.")
    end,
    on_event = function(ch, cond, event)
        if event == "tick" then on_tick(ch, cond) end
    end,
}
