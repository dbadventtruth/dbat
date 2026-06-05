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

return {
  can_see = can_see,
  keywords_for = keywords_for,
  apparent_sex = apparent_sex,
  apparent_race = apparent_race,
  display_name_for = display_name_for,
}
