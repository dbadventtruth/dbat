local transform = require("lua.transform_condition")

return transform.condition({
    id = "oozaru",
    name = "@ROozaru@n",
    family = "oozaru",
    tags = { "transformation", "oozaru" },
    exclusive_tags = { "transformation" },
    bonus = 10000,
    mult = 2.0,
    drain = 0.0,
    requires_pl = 0,
})
