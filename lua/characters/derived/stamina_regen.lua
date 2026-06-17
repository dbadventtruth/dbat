return {
    id = "stamina_regen",
    name = "Stamina Regen",
    modifier_targets = { { "regen", "vitals" } },
    calculate_base = function(ch)
        local pl = ch:der_total("stamina")
        return math.ceil(pl / 8)
    end,
}