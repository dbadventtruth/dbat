local test = require("lua.test").new()
local dbat = require("dbat")

local function mob()
  return dbat.mob_protos.by_id(1):spawn(dbat.rooms.by_id(1))
end

test:case("stat definitions are registered", function(t)
  local strength = dbat.get("stats", "strength")
  t:assert(strength ~= nil, "strength stat should be registered")
  t:eq(strength.default_value, 10)
  t:eq(strength.min_value, 1)
  t:eq(strength.max_value, 100)
end)

test:case("stat get set mod and clamp use Lua definitions", function(t)
  local ch = mob()

  t:eq(ch:stat_set("strength", 50), 50)
  t:eq(ch:stat_get("strength"), 50)

  t:eq(ch:stat_mod("strength", 10), 60)
  t:eq(ch:stat_get("strength"), 60)

  t:eq(ch:stat_set("strength", 150), 100)
  t:eq(ch:stat_get("strength"), 100)

  t:eq(ch:stat_set("strength", -50), 1)
  t:eq(ch:stat_get("strength"), 1)
end)

test:case("unknown stats are inert", function(t)
  local ch = mob()
  t:eq(ch:stat_get("not_a_real_stat"), 0)
  t:eq(ch:stat_set("not_a_real_stat", 123), 0)
  t:eq(ch:stat_mod("not_a_real_stat", 123), 0)
end)

return test:run()
