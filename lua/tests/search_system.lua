local test = require("lua.test").new()
local dbat = require("dbat")
local Search = require("lua.libs.search").new

local function room()
  return assert(dbat.rooms.by_id(1))
end

local function contains_ref(list, ref)
  for _, value in ipairs(list) do
    if value:is_same(ref) then
      return true
    end
  end
  return false
end

test:case("search finds room objects by ordinal and all", function(t)
  local r = room()
  local ch = assert(dbat.mob_protos.by_id(1):spawn(r))
  local first = assert(dbat.obj_protos.by_id(1):spawn(r))
  local second = assert(dbat.obj_protos.by_id(1):spawn(r))

  local search = Search(ch):add_room_objects(r):add_filter(function(searcher, entity)
    return searcher:can_see(entity)
  end)

  local one = assert(search:find_one("1.*"))
  local two = assert(search:find_one("2.*"))
  local all = search:find_all("all.*")

  t:eq(#all, 2)
  t:assert(not one:is_same(two))
  t:assert(contains_ref(all, first))
  t:assert(contains_ref(all, second))

  first:extract()
  second:extract()
  ch:extract()
end)

test:case("search checks providers in added order", function(t)
  local r = room()
  local ch = assert(dbat.mob_protos.by_id(1):spawn(r))
  local room_obj = assert(dbat.obj_protos.by_id(1):spawn(r))
  local inv_obj = assert(dbat.obj_protos.by_id(1):spawn())
  inv_obj:to_char(ch)

  local search = Search(ch):add_character_inventory(ch):add_room_objects(r)

  t:assert(search:find_one("1.*"):is_same(inv_obj))
  t:assert(search:find_one("2.*"):is_same(room_obj))

  inv_obj:extract()
  room_obj:extract()
  ch:extract()
end)

test:case("search can target room characters and global lists", function(t)
  local r = room()
  local viewer = assert(dbat.mob_protos.by_id(1):spawn(r))
  local target = assert(dbat.mob_protos.by_id(2):spawn(r))
  local obj = assert(dbat.obj_protos.by_id(1):spawn(r))

  local people = Search(viewer):add_room_people(r):find_all("all.*")
  t:assert(contains_ref(people, target))
  t:assert(Search(viewer):add_global_characters():find_one("1.*") ~= nil)
  t:assert(Search(viewer):add_global_objects():find_one("1.*") ~= nil)

  obj:extract()
  target:extract()
  viewer:extract()
end)

return test:run()
