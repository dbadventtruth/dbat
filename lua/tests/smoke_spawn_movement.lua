local test = require("lua.test").new()
local dbat = require("dbat")

test:case("mob prototype spawns mobile into a room", function(t)
  local proto = dbat.mob_protos.by_id(1)
  local room = dbat.rooms.by_id(1)
  t:assert(proto ~= nil, "mob proto 1 should exist")
  t:assert(room ~= nil, "room 1 should exist")

  local mob = proto:spawn(room)
  t:assert(mob ~= nil, "spawn should return a character")
  t:eq(mob:is_npc(), true)
  t:eq(mob:proto_id_get(), 1)
  t:eq(mob:room_vnum_get(), 1)
end)

test:case("mobile can move between rooms", function(t)
  local mob = dbat.mob_protos.by_id(2):spawn(dbat.rooms.by_id(2))
  t:eq(mob:room_vnum_get(), 2)

  mob:to_room(dbat.rooms.by_id(3))
  t:eq(mob:room_vnum_get(), 3)

  mob:from_room()
  t:eq(mob:room_get(), nil)
end)

test:case("object prototype spawns object into a room", function(t)
  local proto = dbat.obj_protos.by_id(1)
  local room = dbat.rooms.by_id(4)
  t:assert(proto ~= nil, "object proto 1 should exist")
  t:assert(room ~= nil, "room 4 should exist")

  local obj = proto:spawn(room)
  t:assert(obj ~= nil, "spawn should return an object")
  t:eq(obj:proto_id_get(), 1)
  t:eq(obj:room_vnum_get(), 4)
end)

test:case("object can move between room and inventory", function(t)
  local mob = dbat.mob_protos.by_id(3):spawn(dbat.rooms.by_id(5))
  local obj = dbat.obj_protos.by_id(2):spawn(dbat.rooms.by_id(5))
  t:eq(obj:room_vnum_get(), 5)

  obj:to_char(mob)
  t:eq(obj:room_vnum_get(), -1)
  t:eq(obj:carried_by_get(), mob:id_get())

  obj:to_room(dbat.rooms.by_id(6))
  t:eq(obj:room_vnum_get(), 6)
  t:eq(obj:carried_by_get(), 0)
end)

test:case("object can equip and unequip", function(t)
  local mob = dbat.mob_protos.by_id(4):spawn(dbat.rooms.by_id(7))
  local obj = dbat.obj_protos.by_id(3):spawn()

  obj:equip(mob, 0)
  t:eq(obj:worn_by_get(), mob:id_get())
  t:eq(obj:worn_on_get(), 0)

  local removed = mob:unequip(0)
  t:assert(removed ~= nil, "unequip should return the object")
  t:eq(removed:id_get(), obj:id_get())
  t:eq(removed:worn_by_get(), 0)
end)

return test:run()
