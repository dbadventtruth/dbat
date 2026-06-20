return {
    id   = "bank_interest",
    name = "Bank Interest",
    no_modifiers = true,
    calculate_base = function(ch)
        return math.min(25000, math.floor(ch:stat_get("money_bank") * 0.04))
    end,
}
