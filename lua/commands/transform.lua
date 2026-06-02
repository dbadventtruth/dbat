local function display_transformations(ctx)
    local dbat = require("dbat")
    local transforms = require("lua.transformations")
    local shown = 0

    ctx.ch:send("@WTransformations@n\r\n")
    for id, def in pairs(dbat.category("transformations")) do
        if transforms.visible(def, ctx.ch) then
            local name = def.display_name and def.display_name(ctx.ch) or def.name or id
            local active = transforms.active(def, ctx.ch) and " @G(active)@n" or ""
            local unlocked = transforms.is_unlocked(def, ctx.ch) and "@Gunlocked@n" or "@rhlocked@n"
            ctx.ch:send(string.format("  @C%s@n - %s%s\r\n", name, unlocked, active))
            shown = shown + 1
        end
    end

    if shown == 0 then
        ctx.ch:send("  None.\r\n")
    end
end

local function transform_revert(ctx)
    local dbat = require("dbat")
    local transforms = require("lua.transformations")
    local reverted = 0

    for _, def in pairs(dbat.category("transformations")) do
        if transforms.active(def, ctx.ch) then
            local ok, why = transforms.revert(def, ctx.ch, "reverted")
            if ok then
                local name = def.display_name and def.display_name(ctx.ch) or def.name or def.id
                ctx.ch:send(string.format("You revert from @C%s@n.\r\n", name))
                reverted = reverted + 1
            elseif why then
                ctx.ch:send(why .. "\r\n")
            end
        end
    end

    if reverted == 0 then
        ctx.ch:send("You are not transformed.\r\n")
    end
end

local function transform_apply(ctx)
    local dbat = require("dbat")
    local transforms = require("lua.transformations")
    local form = ctx.argparams.tokens[1]

    if form == nil or form == "" then
        return display_transformations(ctx)
    end

    local def = dbat.get("transformations", form)
    if def == nil then
        ctx.ch:send("No such transformation.\r\n")
        return
    end

    local ok, why = transforms.enter(def, ctx.ch, "command", "transform")
    if not ok then
        ctx.ch:send((why or "You cannot transform into that form.") .. "\r\n")
        return
    end

    local name = def.display_name and def.display_name(ctx.ch) or def.name or def.id
    ctx.ch:send(string.format("You transform into @C%s@n.\r\n", name))
end

local function execute(ctx)
    local subcommand = ctx.argparams.tokens[1]
    if subcommand == nil then
        return display_transformations(ctx)
    end
    if string.lower(subcommand) == "revert" then
        return transform_revert(ctx)
    end
    return transform_apply(ctx)
end

return {
    id = "transform",
    aliases = {{"transform", 5},},
    execute = execute,
}
