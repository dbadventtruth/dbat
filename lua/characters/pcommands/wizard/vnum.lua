local dbat = require("dbat")
local partial_match = require("lua.libs.utils").partial_match

local ITEM = dbat.consts.item_types
-- value slot indices (match C: VAL_ALL_MATERIAL=7, VAL_WEAPON_SKILL=0, VAL_ARMOR_SKILL=1)
local VAL_MATERIAL  = 7
local VAL_WEAPON_SK = 0
local VAL_ARMOR_SK  = 1

local TYPES = { "mob", "obj", "material", "wtype", "atype" }

-- Port of C isname(): case-insensitive abbreviation match against keyword list.
-- Numbers may not be abbreviated.
local function isname(str, namelist)
    if not str or str == "" or not namelist or namelist == "" then return false end
    local lower = str:lower()
    for word in namelist:gmatch("%S+") do
        local wlow = word:lower()
        if wlow:sub(1, #lower) == lower then
            if lower:match("^%d") and lower ~= wlow then return false end
            return true
        end
    end
    return false
end

local function row(found, id, descr, has_trig)
    local trig = has_trig and " [TRIG]" or ""
    return string.format("%3d. [%5d] %-40s%s", found, id, descr or "", trig)
end

local function vnum_mob(ch, name)
    local found = 0
    for proto in dbat.mob_protos.all() do
        if isname(name, proto:name_get() or "") then
            found = found + 1
            ch:send_line(row(found, proto:vnum_get(), proto:short_description_get(), proto:has_trig()))
        end
    end
    return found
end

local function vnum_obj(ch, name)
    local found = 0
    for proto in dbat.obj_protos.all() do
        if isname(name, proto:name_get() or "") then
            found = found + 1
            ch:send_line(row(found, proto:vnum_get(), proto:short_description_get(), proto:has_trig()))
        end
    end
    return found
end

local function vnum_mat(ch, name)
    local mat_names = dbat.consts.material_names
    local found = 0
    for proto in dbat.obj_protos.all() do
        local mat_name = mat_names[proto:value_get(VAL_MATERIAL)] or ""
        if isname(name, mat_name) then
            found = found + 1
            ch:send_line(row(found, proto:vnum_get(), proto:short_description_get(), proto:has_trig()))
        end
    end
    return found
end

local function vnum_wtype(ch, name)
    local wtype_names = dbat.consts.weapon_type_names
    local found = 0
    for proto in dbat.obj_protos.all() do
        if proto:type_get() == ITEM.WEAPON then
            local wname = wtype_names[proto:value_get(VAL_WEAPON_SK)] or ""
            if isname(name, wname) then
                found = found + 1
                ch:send_line(row(found, proto:vnum_get(), proto:short_description_get(), proto:has_trig()))
            end
        end
    end
    return found
end

local function vnum_atype(ch, name)
    local atype_names = dbat.consts.armor_type_names
    local found = 0
    for proto in dbat.obj_protos.all() do
        if proto:type_get() == ITEM.ARMOR then
            local aname = atype_names[proto:value_get(VAL_ARMOR_SK)] or ""
            if isname(name, aname) then
                found = found + 1
                ch:send_line(row(found, proto:vnum_get(), proto:short_description_get(), proto:has_trig()))
            end
        end
    end
    return found
end

local DISPATCH = {
    mob      = function(ch, name) if vnum_mob(ch, name)   == 0 then ch:send_line("No mobiles by that name.")      end end,
    obj      = function(ch, name) if vnum_obj(ch, name)   == 0 then ch:send_line("No objects by that name.")      end end,
    material = function(ch, name) if vnum_mat(ch, name)   == 0 then ch:send_line("No materials by that name.")    end end,
    wtype    = function(ch, name) if vnum_wtype(ch, name) == 0 then ch:send_line("No weapon types by that name.") end end,
    atype    = function(ch, name) if vnum_atype(ch, name) == 0 then ch:send_line("No armor types by that name.")  end end,
}

local function execute(ctx)
    local ch   = ctx.ch
    local toks = ctx.argparams.tokens
    local name = toks[2] or ""
    local typ  = partial_match(TYPES, string.lower(toks[1] or ""))

    if not typ or name == "" then
        ch:send_line("Usage: vnum { atype | material | mob | obj | wtype } <name>")
        return
    end

    DISPATCH[typ](ch, name)
end

return { id = "vnum", aliases = { { "vnum", 2 } }, execute = execute }
