return {
    id   = "lifeforce_regen",
    name = "Lifeforce Regen",
    modifier_targets = { { "regen", "vitals" } },
    calculate_base = function(ch)
        return math.ceil((ch:der_total("ki_regen") + ch:der_total("stamina_regen")) / 4)
    end,
}
