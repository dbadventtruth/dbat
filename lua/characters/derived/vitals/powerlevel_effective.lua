local scale = 1000000

return {
    id = "powerlevel_effective",
    name = "Effective Power Level",
    min_value = 1,
    calculate_base = function(ch)
        local base = ch:der_total("powerlevel")
        local remaining = scale

        local sup = ch:stat_get("suppression")
        if sup > 0 then
            local suppression_remaining = sup * 10000
            if suppression_remaining > scale then suppression_remaining = scale end
            if suppression_remaining < remaining then remaining = suppression_remaining end
        end

        local burden_remaining = scale - ch:der_total("burden")
        if burden_remaining < remaining then remaining = burden_remaining end
        if remaining < 0 then return 0 end
        return (base * remaining) // scale
    end,
}
