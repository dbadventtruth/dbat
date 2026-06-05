local function refs(room)
  return {
    people = room:people_get(),
    contents = room:contents_get(),
  }
end

return {
  refs = refs,
}
