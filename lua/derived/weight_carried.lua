return {
    id = "weight_carried",
    name = "Carried Weight",
    min_value = 0,
    calculate_base = function(ch)
        return ch:der_base("weight_inventory") + ch:der_base("weight_equipment")
    end,
}