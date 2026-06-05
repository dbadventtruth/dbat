local test = require("lua.test").new()
local dbat = require("dbat")

test:case("entity references expose reftype", function(t)
  local room = assert(dbat.rooms.by_id(1))
  local ch = assert(dbat.mob_protos.by_id(1):spawn(room))
  local obj = assert(dbat.obj_protos.by_id(1):spawn(room))

  t:eq(room:reftype(), "room")
  t:eq(ch:reftype(), "character")
  t:eq(obj:reftype(), "object")
  t:eq(dbat.mob_protos.by_id(1):reftype(), "mob_prototype")
  t:eq(dbat.obj_protos.by_id(1):reftype(), "object_prototype")

  obj:extract()
  ch:extract()
end)

test:case("pure Lua character can_see dispatches by reftype", function(t)
  local room = assert(dbat.rooms.by_id(1))
  local viewer = assert(dbat.mob_protos.by_id(1):spawn(room))
  local target = assert(dbat.mob_protos.by_id(2):spawn(room))
  local obj = assert(dbat.obj_protos.by_id(1):spawn(room))

  t:eq(viewer:can_see(target), viewer:can_see_char(target))
  t:eq(viewer:can_see(obj), viewer:can_see_obj(obj))

  obj:extract()
  target:extract()
  viewer:extract()
end)

test:case("pure Lua meta methods are merged into userdata metatables", function(t)
  local room = assert(dbat.rooms.by_id(1))
  local viewer = assert(dbat.mob_protos.by_id(1):spawn(room))
  local target = assert(dbat.mob_protos.by_id(2):spawn(room))
  local obj = assert(dbat.obj_protos.by_id(1):spawn(room))

  t:eq(type(target:keywords_for(viewer)), "table")
  t:eq(type(obj:keywords_for(viewer)), "table")
  t:eq(type(room:refs()), "table")

  obj:extract()
  target:extract()
  viewer:extract()
end)

return test:run()
