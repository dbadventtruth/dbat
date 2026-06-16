local dbat = require("dbat")
dbat.lib = require("lua.lib")
dbat._category_to_namespace = {}

function dbat._register(namespace, category, slug, path, value)
  if value == nil then
    error(path .. " returned nil")
  end

  if not dbat[namespace] then
    dbat[namespace] = {}
  end
  if not dbat[namespace].registry then
    dbat[namespace].registry = {}
  end

  dbat._category_to_namespace[category] = namespace

  local ns = dbat[namespace]
  local bucket = ns.registry[category]
  if bucket == nil then
    bucket = {}
    ns.registry[category] = bucket
  end

  if type(value) == "table" then
    value.id = value.id or slug
    value._path = value._path or path
    value._category = value._category or category
    value._namespace = value._namespace or namespace
  end

  if bucket[slug] ~= nil then
    error("duplicate lua entry: " .. namespace .. "/" .. category .. "/" .. slug)
  end

  bucket[slug] = value
  return value
end

function dbat.get(category, slug)
  local ns_name = dbat._category_to_namespace[category]
  if not ns_name then return nil end
  local bucket = dbat[ns_name].registry[category]
  if not bucket then return nil end
  return bucket[slug]
end

function dbat.category(category)
  local ns_name = dbat._category_to_namespace[category]
  if not ns_name then return {} end
  return dbat[ns_name].registry[category] or {}
end

function dbat._values(list)
  local index = 0
  return function()
    index = index + 1
    return list[index]
  end
end
