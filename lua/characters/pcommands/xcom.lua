return {
    id       = "xcom",
    priority = 1000,
    aliases  = {{"xcom", 4}},
    execute  = function(ctx)
        ctx.ch:send("Move out people!\r\n")
    end,
}
