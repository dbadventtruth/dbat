local M = {}

local Search = {}
Search.__index = Search

local function lower(value)
  return string.lower(tostring(value or ""))
end

local function parse_pattern(pattern)
  local text = tostring(pattern or "")
  local prefix, name = string.match(text, "^([^%.]+)%.(.+)$")

  if prefix == "all" then
    return { all = true, name = name }
  end

  local number = tonumber(prefix)
  if number then
    return { index = number, name = name }
  end

  return { index = 1, name = text }
end

local function entity_keywords(entity, searcher)
  if type(entity) == "userdata" and entity.keywords_for then
    return entity:keywords_for(searcher)
  end
  return { tostring(entity) }
end

local function keyword_matches(keyword, needle)
  if needle == "*" then
    return true
  end

  local key = lower(keyword)
  local text = lower(needle)
  return key == text or string.sub(key, 1, #text) == text
end

local function matches_name(entity, searcher, name)
  if name == "*" then
    return true
  end

  for _, keyword in ipairs(entity_keywords(entity, searcher)) do
    if keyword_matches(keyword, name) then
      return true
    end
  end

  return false
end

local function iterator_from_factory(factory)
  local iter, state, initial = factory()
  if state ~= nil or initial ~= nil then
    return iter, state, initial
  end
  return iter
end

function M.new(searcher)
  return setmetatable({ searcher = searcher, providers = {}, filters = {} }, Search)
end

function Search:add_provider(factory)
  self.providers[#self.providers + 1] = factory
  return self
end

function Search:add_filter(filter)
  self.filters[#self.filters + 1] = filter
  return self
end

function Search:add_room_objects(room)
  return self:add_provider(function()
    return room:contents()
  end)
end

function Search:add_room_people(room)
  return self:add_provider(function()
    return room:people()
  end)
end

function Search:add_character_inventory(ch)
  return self:add_provider(function()
    return ch:inventory()
  end)
end

function Search:add_character_equipment(ch)
  return self:add_provider(function()
    return ch:equipment()
  end)
end

function Search:add_object_inventory(obj)
  return self:add_provider(function()
    return obj:inventory()
  end)
end

function Search:add_global_objects()
  return self:add_provider(function()
    return require("dbat").objects.all()
  end)
end

function Search:add_global_characters()
  return self:add_provider(function()
    return require("dbat").characters.all()
  end)
end

function Search:passes_filters(entity)
  if entity.valid and not entity:valid() then
    return false
  end

  for _, filter in ipairs(self.filters) do
    if not filter(self.searcher, entity) then
      return false
    end
  end

  return true
end

function Search:matches(entity, name)
  return self:passes_filters(entity) and matches_name(entity, self.searcher, name)
end

function Search:find_one(pattern)
  local parsed = parse_pattern(pattern)
  local wanted = parsed.index or 1
  local seen = 0

  for _, provider in ipairs(self.providers) do
    for entity in iterator_from_factory(provider) do
      if self:matches(entity, parsed.name) then
        seen = seen + 1
        if seen == wanted then
          return entity
        end
      end
    end
  end

  return nil
end

function Search:find_all(pattern)
  local parsed = parse_pattern(pattern)
  local results = {}

  if not parsed.all then
    local result = self:find_one(pattern)
    if result ~= nil then
      results[1] = result
    end
    return results
  end

  for _, provider in ipairs(self.providers) do
    for entity in iterator_from_factory(provider) do
      if self:matches(entity, parsed.name) then
        results[#results + 1] = entity
      end
    end
  end

  return results
end

function Search:find(pattern)
  local parsed = parse_pattern(pattern)
  if parsed.all then
    return self:find_all(pattern)
  end
  return self:find_one(pattern)
end

M.Search = Search
M.parse_pattern = parse_pattern

return M
