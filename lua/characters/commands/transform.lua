local function display_transformations(ctx)
    local dbat = require("dbat")
    local transforms = dbat.lib.transforms
    local shown = 0

    ctx.ch:send("@WTransformations@n\r\n")
    for _, entry in ipairs(transforms.visible_list(ctx.ch)) do
        local id = entry.id
        local def = entry.def
        local name = transforms.display_name(def, ctx.ch) or id
        local active = transforms.active(def, ctx.ch) and " @G(active)@n" or ""
        local unlocked = transforms.is_unlocked(def, ctx.ch) and "@Gunlocked@n" or "@rlocked@n"
        ctx.ch:send(string.format("  @C%s@n - %s%s\r\n", name, unlocked, active))
        shown = shown + 1
    end

    if shown == 0 then
        ctx.ch:send("  None.\r\n")
    end
end

local function transform_revert(ctx)
    local dbat = require("dbat")
    local transforms = dbat.lib.transforms
    local reverted = 0

    for _, def in pairs(dbat.category("transformations")) do
        if transforms.active(def, ctx.ch) then
            ctx.ch:release_charge()
            local ok, why = transforms.revert(def, ctx.ch, "reverted")
            if ok then
                local name = transforms.display_name(def, ctx.ch) or def.id
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
    local transforms = dbat.lib.transforms
    local form = ctx.argparams.raw

    if form == nil or form == "" then
        return display_transformations(ctx)
    end

    local def = transforms.resolve(ctx.ch, form)
    if def == nil then
        ctx.ch:send("No such transformation.\r\n")
        return
    end

    local ok, why = transforms.enter(def, ctx.ch, "command", "transform")
    if not ok then
        ctx.ch:send((why or "You cannot transform into that form.") .. "\r\n")
        return
    end

    local name = transforms.display_name(def, ctx.ch) or def.id
    local msg_context = { actor = ctx.ch }
    local msg_self = def.msg_transform_self or string.format("You transform into @C%s@n.\r\n", name)
    dbat.lib.act.to_char(ctx.ch, msg_self, msg_context)
    local msg_others = def.msg_transform_others or string.format("@C$n@W transforms into @C%s@n.\r\n", name)
    dbat.lib.act.around(ctx.ch, msg_others, msg_context)

    ctx.ch:reveal_hiding(0)

    if def.zone_echo ~= false then
        local zone = ctx.ch:zone_get()
        if zone ~= nil then
            zone:send_text(def.zone_echo or "An explosion of power ripples through the surrounding area!\r\n")
        end
    end

    ctx.ch:send_to_sense(0, def.sense_echo or "You sense a nearby power grow unbelievably!")
    ctx.ch:send_to_scouter(string.format("@D[@GBlip@D]@r Transformed Powerlevel@D: [@Y%s@D]", dbat.lib.text.add_commas(ctx.ch:meter_current("powerlevel"))), 1, 0)
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
