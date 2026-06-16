return {
    id = "starphase",
    name = "Starphase",
    alias = { "star", "phase" },
    races = { "hoshijin" },
    sort_order = 1201,
    family = "starphase",
    condition = "starphase",
    available = function(ch) return ch:race_get() == "hoshijin" end,
}
