

local function refs(room)
  return {
    people = room:people_get(),
    contents = room:contents_get(),
  }
end

-- Modifiers applied to characters in the room.
local function modifiers(room)
  local mods = {}

  -- regen Room
  if room:flagged(29) and room:damage_get() < 75 then
    mods[#mods + 1] = { target = { "regen", "vitals" }, kind = "percent", value = 50000, label = "Regen Room" }
  end

  -- bedrooms
  if room:flagged(57) then
    mods[#mods + 1] = { target = { "regen", "vitals" }, kind = "percent", value = 25000, label = "Bedroom" }
  end

  -- aura rooms
  if room:flagged(40) then
    mods[#mods + 1] = { target = { "regen", "vitals" }, kind = "percent", value = 50000000, label = "Aura Room" }
  end

  local cook = room:cook_element()
  if cook > 0 then
    local label = "Campfire"
    if cook == 2 then label = "Flambus Stove" end
    mods[#mods + 1] = { target = { "regen", "vitals" }, kind = "percent", value = 50000, label = label }
  end

  return mods
end

local function on_mud_hour(room)
end

local function on_second(room)
end

local function on_heartbeat(room, hb)
end

return {
  refs = refs,
  modifiers = modifiers,
  on_mud_hour = on_mud_hour,
  on_second = on_second,
  on_heartbeat = on_heartbeat,
}
