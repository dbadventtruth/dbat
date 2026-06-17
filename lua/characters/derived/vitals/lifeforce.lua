return {
    id = "lifeforce",
    name = "Life Force",
    min_value = 0,
    legacy_modifiers = {{22, -1}},
    calculate_base = function(ch)
        if ch:race_get() == "android" then
            return 0
        end
        return math.floor((ch:der_total("ki") + ch:der_total("stamina")) / 2)
    end,
}
