local M = {}

local function case_sensitive(opts)
  return opts and (opts.case == true or opts.case == "sensitive")
end

local function string_for(value, opts)
  if opts and opts.str_func then
    return tostring(opts.str_func(value))
  end
  return tostring(value)
end

local function normalize(value, opts)
  if case_sensitive(opts) then
    return value
  end
  return string.lower(value)
end

local function starts_with(value, prefix)
  return string.sub(value, 1, #prefix) == prefix
end

local function candidates(list, input, opts)
  local needle = normalize(tostring(input or ""), opts)
  local exact = {}
  local prefix = {}

  for index, value in ipairs(list) do
    local text = string_for(value, opts)
    local comparable = normalize(text, opts)
    local candidate = { value = value, text = text, index = index }

    if comparable == needle then
      exact[#exact + 1] = candidate
    elseif starts_with(comparable, needle) then
      prefix[#prefix + 1] = candidate
    end
  end

  if #exact > 0 then
    return exact
  end

  table.sort(prefix, function(left, right)
    if #left.text == #right.text then
      return left.index < right.index
    end
    return #left.text < #right.text
  end)

  return prefix
end

function M.partial_matches(list, input, opts)
  local matches = candidates(list, input, opts or {})
  local values = {}
  for index, match in ipairs(matches) do
    values[index] = match.value
  end
  return values
end

function M.partial_match(list, input, opts)
  opts = opts or {}
  if opts.mode == "multi" then
    return M.partial_matches(list, input, opts)
  end

  local matches = candidates(list, input, opts)
  if matches[1] then
    return matches[1].value
  end
  return nil
end

return M
