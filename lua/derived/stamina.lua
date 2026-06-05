local multiform = require("lua.libs.multiform")

return {
    id = "stamina",
    name = "Stamina",
    min_value = 1,
    legacy_modifiers = {{14, -1}},
    calculate_base = function(ch)
        return multiform.base(ch, "stamina")
    end,
}
