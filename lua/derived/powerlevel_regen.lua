return {
    id = "powerlevel_regen",
    name = "Powerlevel Regen",
    modifier_targets = { { "regen", "vitals" } },
    calculate_base = function(ch)
        local pl = ch:der_total("powerlevel")
        return math.ceil(pl / 15)
    end,
}