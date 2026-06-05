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
end

local function apparent_race(ch, viewer)
  viewer = viewer or ch
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
}
