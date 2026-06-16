return {
    id = "weight_total",
    name = "Total Weight",
    min_value = 0,
    calculate_base = function(ch)
        return ch:der_base("weight_carried") + ch:der_base("weight")
    end,
}
