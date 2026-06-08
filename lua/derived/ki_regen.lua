return {
    id = "ki_regen",
    name = "Ki Regen",
    modifier_targets = { { "regen", "vitals" } },
    calculate_base = function(ch)
        local pl = ch:der_total("ki")
        return math.ceil(pl / 12)
    end,
}