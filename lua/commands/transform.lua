local function display_transformations(ctx)
    local dbat = require("dbat")
    local transforms = require("lua.transformations")
    local shown = 0
    local visible = {}

    for id, def in pairs(dbat.category("transformations")) do
        if transforms.visible(def, ctx.ch) then
            visible[#visible + 1] = { id = id, def = def }
        end
    end

    table.sort(visible, function(a, b)
        local a_order = a.def.sort_order or 100000
        local b_order = b.def.sort_order or 100000
        if a_order ~= b_order then return a_order < b_order end
        return (a.def.name or a.id) < (b.def.name or b.id)
    end)

    ctx.ch:send("@WTransformations@n\r\n")
    for _, entry in ipairs(visible) do
        local id = entry.id
        local def = entry.def
        local name = def.display_name and def.display_name(ctx.ch) or def.name or id
        local active = transforms.active(def, ctx.ch) and " @G(active)@n" or ""
        local unlocked = transforms.is_unlocked(def, ctx.ch) and "@Gunlocked@n" or "@rhlocked@n"
        ctx.ch:send(string.format("  @C%s@n - %s%s\r\n", name, unlocked, active))
        shown = shown + 1
    end

    if shown == 0 then
        ctx.ch:send("  None.\r\n")
    end
end

local function normalize_form_name(value)
    return string.lower(tostring(value or "")):gsub("[^%w]+", "")
end

local function alias_matches(alias, needle)
    if alias == nil then return false end
    if type(alias) == "table" then
        for _, value in ipairs(alias) do
            if normalize_form_name(value) == needle then return true end
        end
        return false
    end
    return normalize_form_name(alias) == needle
end

local function resolve_transformation(form, ch)
    local dbat = require("dbat")
    local transforms = require("lua.transformations")
    local exact = dbat.get("transformations", form)

    if exact ~= nil and transforms.visible(exact, ch) then return exact end

    local needle = normalize_form_name(form)
    for id, def in pairs(dbat.category("transformations")) do
        if transforms.visible(def, ch) then
            local display_name = def.display_name and def.display_name(ch) or def.name
            if normalize_form_name(id) == needle or normalize_form_name(def.name) == needle or normalize_form_name(display_name) == needle or alias_matches(def.alias, needle) then
                return def
            end
        end
    end

    return nil
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
    local form = ctx.argparams.raw

    if form == nil or form == "" then
        return display_transformations(ctx)
    end

    local def = resolve_transformation(form, ctx.ch)
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
