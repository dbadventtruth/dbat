local M = {}

local function call_or_value(value, ch, def)
    if type(value) == "function" then return value(ch, def) end
    return value
end

local function available(def, ch)
    if def.races ~= nil then
        local race = ch:race_get()
        local allowed = false
        for _, race_id in ipairs(def.races) do
            if race == race_id then
                allowed = true
                break
            end
        end
        if not allowed then return false end
    end

    local result = call_or_value(def.available, ch, def)
    if result == nil then return true end
    return result and true or false
end

local function transform_id(def)
    return assert(def.id, "transformation is missing id")
end

local function condition_id(def)
    if def.condition == false then return nil end
    return def.condition
end

local function reason(text)
    return false, text
end

function M.visible(def, ch)
    if def.visible ~= nil then return call_or_value(def.visible, ch, def) and true or false end
    return available(def, ch)
end

function M.is_unlocked(def, ch)
    if def.is_unlocked ~= nil then return call_or_value(def.is_unlocked, ch, def) and true or false end
    return ch:transform_unlocked(transform_id(def))
end

function M.can_unlock(def, ch)
    if def.can_unlock ~= nil then return def.can_unlock(ch, def) end
    if not M.visible(def, ch) then return reason("You do not know of that transformation.") end
    if M.is_unlocked(def, ch) then return reason("That transformation is already unlocked.") end
    return true
end

function M.unlock(def, ch, source)
    return ch:transform_unlock(transform_id(def), source or "lua")
end

function M.requires_pl(def, ch)
    local value = def.requires_pl
    if type(value) == "function" then return value(ch) or 0 end
    return value or 0
end

function M.active(def, ch)
    local condition = condition_id(def)
    return condition ~= nil and ch:condition_has(condition) or false
end

function M.can_enter(def, ch)
    if def.can_enter ~= nil then return def.can_enter(ch, def) end
    if not M.visible(def, ch) then return reason("You do not know of that transformation.") end
    if not M.is_unlocked(def, ch) then return reason("That transformation is not unlocked.") end
    if M.active(def, ch) then return reason("You are already using that transformation.") end
    local required = M.requires_pl(def, ch)
    if required > 0 and ch:der_total("powerlevel") < required then return reason("You are not powerful enough.") end
    return true
end

function M.enter(def, ch, source_category, source_id)
    if def.enter ~= nil then return def.enter(ch, def) end
    local ok, why = M.can_enter(def, ch)
    if not ok then return ok, why end
    local condition = condition_id(def)
    if condition ~= nil then
        return ch:condition_apply(condition, source_category or "transformation", source_id or transform_id(def))
    end
    ch:transform_number_set(transform_id(def), "active", 1)
    return true
end

function M.can_revert(def, ch)
    if def.can_revert ~= nil then return def.can_revert(ch, def) end
    local condition = condition_id(def)
    if condition ~= nil then
        if not ch:condition_has(condition) then return reason("You are not using that transformation.") end
        return true
    end
    if ch:transform_number_get(transform_id(def), "active") == 0 then return reason("You are not using that transformation.") end
    return true
end

function M.revert(def, ch, reason_text)
    if def.revert ~= nil then return def.revert(ch, def) end
    local ok, why = M.can_revert(def, ch)
    if not ok then return ok, why end
    local condition = condition_id(def)
    if condition ~= nil then return ch:condition_remove(condition, reason_text or "reverted") end
    ch:transform_number_set(transform_id(def), "active", 0)
    return true
end

return M
