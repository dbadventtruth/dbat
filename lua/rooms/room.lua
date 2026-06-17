

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

local function send_text(room, msg, ...)
  local text = select('#', ...) > 0 and string.format(msg, ...) or msg
  for ch in room:people() do
    ch:send_raw(text)
  end
end

local function send_line(room, msg, ...)
  local text = select('#', ...) > 0 and string.format(msg, ...) or msg
  if not text:match("\r\n$") then text = text .. "\r\n" end
  for ch in room:people() do
    ch:send_raw(text)
  end
end

local function on_update(room, kind)
  local subsystem, id, event_name = kind:match("^([^:]+):([^:]+):?(.*)$")
  event_name = (event_name and event_name ~= "") and event_name or "tick"
  _ = subsystem
  _ = id
  _ = event_name
  -- future: route to room-based subsystems
end

return {
  refs = refs,
  modifiers = modifiers,
  send_text = send_text,
  send_line = send_line,
  on_update = on_update,
}
