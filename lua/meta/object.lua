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

return {
  keywords_for = keywords_for,
  display_name_for = display_name_for,
}
