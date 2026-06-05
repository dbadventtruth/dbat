return {
    id = "weight_carry_capacity",
    name = "Carry Capacity",
    min_value = 1,
    calculate_base = function(ch)
        local str_mod = ch:der_total("strength") * 50
        local pl_mod = ch:der_total("powerlevel") // 200
        return str_mod + pl_mod
    end,
}
