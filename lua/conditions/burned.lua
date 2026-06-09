return {
    id = "burned",
    name = "Burned",
    tags = { "burned", "injury", "healthy_clear" },
    persistent = true,

    on_remove = function(ch, cond, reason)
        ch:act_self("Your burns have healed.")
        ch:act_around("$n@n's burns have healed.", {hide_invisible = true})
    end,
}
