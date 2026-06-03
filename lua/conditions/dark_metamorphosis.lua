return {
    id = "dark_metamorphosis",
    name = "Dark Metamorphosis",
    tags = { "power_amp", "dark_metamorphosis" },
    persistent = false,
    modifiers = function()
        return {
            { target = { "derived", "powerlevel" }, kind = "percent", value = 6000, label = "Dark Metamorphosis" },
        }
    end,
}
