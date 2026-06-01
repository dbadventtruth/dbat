local M = {}

local function scale(mult)
    return math.floor((mult or 1.0) * 10000)
end

local function form_from(def, ch, condition)
    if def.form ~= nil then return def.form(ch, condition) end
    return def
end

local function power_modifiers(form)
    if form == nil then return {} end
    local name = form.name or form.id or "Transformation"
    local bonus = form.bonus or 0
    local mult = scale(form.mult)
    local result = {}

    if bonus ~= 0 then
        result[#result + 1] = { target = { "derived", "powerlevel" }, kind = "flat", value = bonus, label = name }
        result[#result + 1] = { target = { "derived", "ki" }, kind = "flat", value = bonus, label = name }
        result[#result + 1] = { target = { "derived", "stamina" }, kind = "flat", value = bonus, label = name }
    end

    if mult ~= 10000 then
        result[#result + 1] = { target = { "derived", "powerlevel" }, kind = "multiplier", value = mult, label = name }
        result[#result + 1] = { target = { "derived", "ki" }, kind = "multiplier", value = mult, label = name }
        result[#result + 1] = { target = { "derived", "stamina" }, kind = "multiplier", value = mult, label = name }
    end

    return result
end

function M.condition(def)
    return {
        id = def.id,
        name = def.display or def.name,
        tags = def.tags or { "transformation", def.family or def.id },
        exclusive_tags = def.exclusive_tags or { "transformation" },
        persistent = def.persistent ~= false,
        modifiers = function(ch, condition)
            return power_modifiers(form_from(def, ch, condition))
        end,
    }
end

function M.transformation(def)
    return {
        id = def.id,
        name = def.display or def.name,
        family = def.family,
        tier = def.tier,
        condition = def.condition or def.id,
        rpp_cost = def.rpp_cost or 0,
        form = def.form,
        available = def.available or function(ch) return form_from(def, ch, nil) ~= nil end,
        display_name = function(ch)
            local form = form_from(def, ch, nil)
            return form and (form.name or def.name) or def.name
        end,
        requires_pl = function(ch)
            local form = form_from(def, ch, nil)
            return form and (form.requires_pl or def.requires_pl or 0) or 0
        end,
        bonus = function(ch)
            local form = form_from(def, ch, nil)
            return form and (form.bonus or 0) or 0
        end,
        mult = function(ch)
            local form = form_from(def, ch, nil)
            return form and (form.mult or 1.0) or 1.0
        end,
        drain = function(ch)
            local form = form_from(def, ch, nil)
            return form and (form.drain or 0.0) or 0.0
        end,
        msg_transform_self = def.msg_transform_self or "",
        msg_transform_others = def.msg_transform_others or "",
    }
end

return M
