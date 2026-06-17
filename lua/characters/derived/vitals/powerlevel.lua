local multiform = require("lua.libs.multiform")

return {
    id = "powerlevel",
    name = "Power Level",
    min_value = 1,
    legacy_modifiers = {{13, -1}},
    calculate_base = function(ch)
        return multiform.base(ch, "powerlevel")
    end,
}
