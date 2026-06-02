return {
    id = "starphase",
    name = "Starphase",
    alias = { "star", "phase" },
    races = { 14 },
    sort_order = 1201,
    family = "starphase",
    condition = "starphase",
    available = function(ch) return ch:race_get() == 14 end,
}
