return {
    id = "lifeforce",
    name = "Life Force",
    min_value = 1,
    legacy_modifiers = {{22, -1}},
    calculate_base = function(ch)
        return math.floor((ch:der_total("ki") + ch:der_total("stamina")) / 2)
    end,
}
