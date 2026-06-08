local function can_see(ch, entref)
  local kind = entref and entref:reftype()

  if kind == "character" then
    return ch:can_see_char(entref)
  end
  if kind == "object" then
    return ch:can_see_obj(entref)
  end

  error("Character:can_see expected character or object", 2)
end

local function apparent_sex(ch, viewer)
  viewer = viewer or ch

  return ch:sex_get()
end

local function apparent_race(ch, viewer)
  viewer = viewer or ch

  return ch:race_get()
end

local function display_name_for(ch, viewer)
  viewer = viewer or ch

  -- viewer is looking at an NPC, so we just have short descriptions.
  if(ch:is_npc()) then
    return ch:short_description_get()
  end

  -- Okay so ch is a player then.

  -- NPCs and admins can always see player names.
  if(viewer:is_npc() or viewer:admin_level_get() > 0) then
    return ch:name_get()
  end

  -- If we reached this far, we're a player looking at another player.
  -- TODO: use the dub system! For now, just show the name.
  return ch:name_get()
end

local function keywords_for(ch, viewer)
  viewer = viewer or ch
  local keywords = {}

  local name = ch:name_get()
  for word in string.gmatch(name or "", "%S+") do
    keywords[#keywords + 1] = word
  end

  return keywords
end

local function find_in_registry(category, legacy_id)
  local registry = dbat.registry[category]
  if not registry then return nil end
  for _, entry in pairs(registry) do
    if entry.legacy_id == legacy_id then
      return entry
    end
  end
  return nil
end

local function append_mods(out, mods)
  for _, m in ipairs(mods or {}) do
    out[#out + 1] = m
  end
end

local function modifiers(ch)
  local all = {}

  -- Race
  local race_id = ch:race_get()
  if race_id then
    local entry = find_in_registry("races", race_id)
    if entry and entry.modifiers then
      append_mods(all, entry.modifiers(ch))
    end
  end

  -- Sensei
  local sensei_id = ch:sensei_get()
  if sensei_id then
    local entry = find_in_registry("senseis", sensei_id)
    if entry and entry.modifiers then
      append_mods(all, entry.modifiers(ch))
    end
  end

  -- Conditions
  for _, cond_id in ipairs(ch:conditions()) do
    local cond = ch:condition(cond_id)
    local cond_def = dbat.registry.conditions[cond_id]
    if cond_def and cond_def.modifiers then
      append_mods(all, cond_def.modifiers(ch, cond))
    end
  end

  -- Room
  local room = ch:room_get()
  if room then
    append_mods(all, room:modifiers())
  end

  -- Sitting object
  local obj = ch:sits_get()
  if obj then
    append_mods(all, obj:modifiers())
  end

  return all
end

local function on_mud_hour(ch)
end

local function on_second(ch)
end

local function on_heartbeat(ch, hb)
end

return {
  can_see = can_see,
  keywords_for = keywords_for,
  modifiers = modifiers,
  apparent_sex = apparent_sex,
  apparent_race = apparent_race,
  display_name_for = display_name_for,
  on_mud_hour = on_mud_hour,
  on_second = on_second,
  on_heartbeat = on_heartbeat,
}
