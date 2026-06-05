local multiform = require("lua.libs.multiform")

return {
    id = "ki",
    name = "Ki",
    min_value = 1,
    legacy_modifiers = {{12, -1}, {37, -1}},
    calculate_base = function(ch)
        return multiform.base(ch, "ki")
    end,
}
