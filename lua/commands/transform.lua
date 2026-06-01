local function execute(ctx)
    local dbat = require("dbat")
    ctx.ch:send("Lua transform command is wired.\r\n")
    dbat.log("transform command: " .. ctx.arguments)
end

return {
    id = "transform",
    aliases = {{"transform", 5},},
    execute = execute,
}
