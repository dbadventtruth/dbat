local test = require("lua.test").new()
local dbat = require("dbat")

local function mob()
  return dbat.mob_protos.by_id(1):spawn(dbat.rooms.by_id(1))
end

test:case("meter definitions are registered", function(t)
  local ki = dbat.get("meters", "ki")
  t:assert(ki ~= nil, "ki meter should exist")
  t:eq(ki.derived_stat, "ki")
end)

test:case("meter max follows derived stat", function(t)
  local ch = mob()
  ch:stat_set("ki", 1000)
  t:eq(ch:meter_max("ki"), 1000)
  t:eq(ch:meter_current("ki"), 1000)
end)

test:case("meter fixed and integer access clamp correctly", function(t)
  local ch = mob()
  ch:stat_set("ki", 1000)

  t:eq(ch:meter_set("ki", 5000), 5000)
  t:eq(ch:meter_get("ki"), 5000)
  t:assert(ch:meter_current("ki") > 0)
  t:assert(ch:meter_current("ki") <= ch:meter_max("ki"))

  local modded = ch:meter_mod("ki", 8000)
  t:eq(ch:meter_get("ki"), modded)
  t:assert(modded > 5000)
  t:assert(ch:meter_current("ki") > 0)
  t:assert(ch:meter_current("ki") <= ch:meter_max("ki"))

  local max = ch:meter_max("ki")
  local half = math.floor(max / 2)
  t:assert(ch:meter_set_int("ki", half) >= 0)
  t:assert(ch:meter_current("ki") >= 0)
  t:assert(ch:meter_current("ki") <= ch:meter_max("ki"))

  t:eq(ch:meter_mod_int("ki", -500), 0)
  t:eq(ch:meter_current("ki"), 0)
end)

return test:run()
