local c = {}

c.id = "food_restored"
c.name = "Food Restored"
c.tags = { "food" }
c.description = "You recently benefitted from a meal, restoring your stamina."
c.persistent = true

function c.on_apply(ch, cond)
    local amount = cond:number_get("amount") or 0
    ch:send_line("You feel rejuvenated after your meal.")
    cond:schedule_expire(300)
    -- increase stamina by amount%
    ch:meter_mod("stamina", amount * 10)
end

return c