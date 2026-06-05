local function keywords_for(obj, viewer)
  local keywords = {}

  local name = obj:name_get()
  for word in string.gmatch(name or "", "%S+") do
    keywords[#keywords + 1] = word
  end

  local short = obj:short_description_get()
  if short and short ~= "" and (viewer == nil or viewer:can_see(obj)) then
    keywords[#keywords + 1] = short
  end

  return keywords
end

return {
  keywords_for = keywords_for,
}
