local function is_abbrev(input, full)
    if #input == 0 then return false end
    return string.lower(string.sub(full, 1, #input)) == string.lower(input)
end

local function execute(ctx)
    local ch   = ctx.ch
    local toks = ctx.argparams.tokens
    local typ  = string.lower(toks[1] or "")
    local name = toks[2] or ""

    if typ == "" or name == "" or
       (not is_abbrev(typ, "mob") and not is_abbrev(typ, "obj") and
        not is_abbrev(typ, "mat") and not is_abbrev(typ, "wtype") and
        not is_abbrev(typ, "atype"))
    then
        ch:send_line("Usage: vnum { atype | material | mob | obj | wtype } <name>")
        return
    end

    if is_abbrev(typ, "mob") then
        if not ch:vnum_mob(name) then ch:send_line("No mobiles by that name.") end
    end
    if is_abbrev(typ, "obj") then
        if not ch:vnum_obj(name) then ch:send_line("No objects by that name.") end
    end
    if is_abbrev(typ, "mat") then
        if not ch:vnum_mat(name) then ch:send_line("No materials by that name.") end
    end
    if is_abbrev(typ, "wtype") then
        if not ch:vnum_wtype(name) then ch:send_line("No weapon types by that name.") end
    end
    if is_abbrev(typ, "atype") then
        if not ch:vnum_atype(name) then ch:send_line("No armor types by that name.") end
    end
end

return { id = "vnum", aliases = { { "vnum", 2 } }, execute = execute }
