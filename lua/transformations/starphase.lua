return {
    id = "starphase",
    name = "Starphase",
    family = "starphase",
    condition = "starphase",
    available = function(ch) return ch:race_get() == 14 end,
}
