local function keywords_for(obj, viewer)
  local keywords = {}

  local name = obj:name_get()
  for word in string.gmatch(name or "", "%S+") do
    keywords[#keywords + 1] = word
  end

  return keywords
end

local function display_name_for(obj, viewer, prefix)
  viewer = viewer or obj

  return obj:short_description_get()
end

-- This is used for furniture-based modifiers.
local function modifiers(obj)
  local mods = {}

  local vital_regen = 10000

  -- nice furniture
  if obj:proto_id_get() == 19090 then
    vital_regen = vital_regen + 10000
  end
  if obj:proto_id_get() == 19091 then
    vital_regen = vital_regen + 30000
  end

  -- healing tanks
  if obj:proto_id_get() == 65 then
    vital_regen = 200000
  end

  if vital_regen ~= 0 then
    local label = obj:short_description_get()
    mods[#mods + 1] = { target = { "regen", "vitals" }, kind = "percent", value = vital_regen, label = label }
  end

  return mods
end

local function on_mud_hour(obj)
end

local function on_second(obj)
end

local function on_heartbeat(obj, hb)
end

return {
  keywords_for = keywords_for,
  display_name_for = display_name_for,
  modifiers = modifiers,
  on_mud_hour = on_mud_hour,
  on_second = on_second,
  on_heartbeat = on_heartbeat,
}
