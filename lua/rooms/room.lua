

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

local function on_event(room, kind)
  local subsystem, id, event_name = kind:match("^([^:]+):([^:]+):?(.*)$")
  event_name = (event_name and event_name ~= "") and event_name or "tick"
  _ = subsystem
  _ = id
  _ = event_name
  -- future: route to room-based subsystems
end

-- Port of check_saveroom_count(ch, NULL) — counts items in a house room for
-- capacity enforcement. Returns 0 for non-house rooms. Non-cardcase containers
-- contribute 1 + half their contents (recursively).
local function saveroom_count(room)
  local d = require("dbat")
  local RF = d.consts.room_flags
  local EF = d.consts.item_extra_flags
  local IT = d.consts.item_types

  if not room:flagged(RF.HOUSE) then return 0 end

  local function insidebag(obj, mult)
    local count = 0
    local containers = 0
    for inner in obj:inventory() do
      if inner:type_get() == IT.CONTAINER then
        count = count + 1 + insidebag(inner, mult)
        containers = containers + 1
      else
        count = count + 1
      end
    end
    return math.floor(count * mult) + containers
  end

  local count = 0
  for obj in room:contents() do
    count = count + 1
    if not obj:extra_flagged(EF.CARDCASE) then
      count = count + insidebag(obj, 0.5)
    end
  end
  return count
end

-- Render the character-list section of a room as seen by viewer.
-- Returns a string. Mirrors list_char_to_char() in act.informative.cpp.
local function render_chars_for(room, viewer)
  local d = require("dbat")
  local character = d.characters
  local PRF = d.consts.prf_flags

  -- Collect people in order
  local people = {}
  for ch in room:people() do people[#people+1] = ch end

  local shown = {}
  local t = {}

  for i, ch in ipairs(people) do
    -- Skip self
    if ch:id_get() == viewer:id_get() then goto next end
    -- Skip dot-prefix NPC long_descs unless viewer has HOLYLIGHT
    if ch:is_npc() and not viewer:pref_flagged(PRF.HOLYLIGHT) then
      local ld = ch:long_description_get()
      if ld and ld:sub(1, 1) == "." then goto next end
    end
    -- Visibility check
    if not viewer:can_see_char(ch) then goto next end
    if shown[i] then goto next end

    -- Stacking for identical idle NPCs
    local key   = character.stack_key(ch)
    local count = 1
    shown[i] = true
    if key then
      for j = i + 1, #people do
        if not shown[j] and viewer:can_see_char(people[j])
            and character.stack_key(people[j]) == key then
          count = count + 1
          shown[j] = true
        end
      end
    end

    if count > 1 then
      t[#t+1] = string.format("@D(@R%dx@D)@n ", count)
    end
    t[#t+1] = character.render_room_line(ch, viewer)
    ::next::
  end

  return table.concat(t)
end

return {
  refs = refs,
  modifiers = modifiers,
  send_text = send_text,
  send_line = send_line,
  on_event = on_event,
  render_chars_for = render_chars_for,
  saveroom_count = saveroom_count,
}
