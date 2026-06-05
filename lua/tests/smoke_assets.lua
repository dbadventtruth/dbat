local test = require("lua.test").new()
local dbat = require("dbat")

test:case("test mode is enabled", function(t)
  t:eq(dbat.test.mode_enabled(), true)
end)

test:case("required room 0 exists and is isolated fixture", function(t)
  local room = dbat.rooms.by_id(0)
  t:assert(room ~= nil, "room 0 should exist")
  t:eq(room:vnum_get(), 0)
  t:eq(room:name_get(), "The Test Void")
end)

test:case("linked test corridor rooms exist", function(t)
  for vnum = 1, 10 do
    local room = dbat.rooms.by_id(vnum)
    t:assert(room ~= nil, "missing room " .. vnum)
    t:eq(room:vnum_get(), vnum)
  end
end)

test:case("test zones exist", function(t)
  local void = dbat.zones.by_id(0)
  local grounds = dbat.zones.by_id(1)
  t:assert(void ~= nil, "zone 0 should exist")
  t:assert(grounds ~= nil, "zone 1 should exist")
  t:eq(void:name_get(), "Test Void")
  t:eq(grounds:name_get(), "Test Grounds")
end)

test:case("test mobile prototypes exist", function(t)
  for vnum = 1, 10 do
    t:assert(dbat.test.mob_proto_exists(vnum), "missing mob prototype " .. vnum)
  end
end)

test:case("test object prototypes exist", function(t)
  for vnum = 1, 10 do
    t:assert(dbat.test.obj_proto_exists(vnum), "missing object prototype " .. vnum)
  end
end)

return test:run()
