return {
    id   = "money_max_carry",
    name = "Max Money",
    no_modifiers = true,
    calculate_base = function(ch)
        local lv = ch:stat_get("level")
        if lv < 50 then return lv * 10000
        elseif lv < 100 then return 500000
        else return 50000000 end
    end,
}
