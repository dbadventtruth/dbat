local test = require("lua.test").new()
local dbat = require("dbat")

local RACE_SAIYAN = 1

local function mob()
  return dbat.mob_protos.by_id(1):spawn(dbat.rooms.by_id(1))
end

test:case("transformation definitions are registered", function(t)
  local ssj = dbat.get("transformations", "super_saiyan_1")
  t:assert(ssj ~= nil, "super_saiyan_1 should exist")
  t:eq(ssj.family, "super_saiyan")
  t:eq(ssj.tier, 1)
end)

test:case("transformation availability and metadata functions work", function(t)
  local ch = mob()
  ch:race_set(RACE_SAIYAN)
  ch:stat_set("powerlevel", 1200000)

  local ssj = dbat.get("transformations", "super_saiyan_1")
  t:eq(ssj.available(ch), true)
  t:eq(ssj.requires_pl(ch), 1200000)
  t:eq(ssj.bonus(ch), 800000)
  t:eq(ssj.mult(ch), 2.0)
end)

test:case("transformation unlock state persists on character", function(t)
  local ch = mob()
  t:eq(ch:transform_has("super_saiyan_1"), false)
  t:eq(ch:transform_unlocked("super_saiyan_1"), false)

  t:eq(ch:transform_unlock("super_saiyan_1", "test-suite"), true)
  t:eq(ch:transform_has("super_saiyan_1"), true)
  t:eq(ch:transform_unlocked("super_saiyan_1"), true)
  t:eq(ch:transform_number_get("super_saiyan_1", "unlocked"), 1)
  t:eq(ch:transform_string_get("super_saiyan_1", "unlock_source"), "test-suite")

  t:eq(ch:transform_number_mod("super_saiyan_1", "uses", 2), 2)
  t:eq(ch:transform_number_get("super_saiyan_1", "uses"), 2)
  t:eq(ch:transform_remove("super_saiyan_1"), true)
  t:eq(ch:transform_has("super_saiyan_1"), false)
end)

test:case("transformation condition modifies derived stats", function(t)
  local ch = mob()
  ch:race_set(RACE_SAIYAN)
  ch:stat_set("powerlevel", 1000)
  ch:stat_set("ki", 1000)
  ch:stat_set("stamina", 1000)

  t:eq(ch:condition_apply("super_saiyan_1"), true)
  t:eq(ch:condition_has("super_saiyan_1"), true)
  t:eq(ch:condition_has_tag("transformation"), true)

  t:eq(ch:der_total("powerlevel"), 1602000)
  t:eq(ch:der_total("ki"), 1602000)
  t:eq(ch:der_total("stamina"), 1602000)

  t:eq(ch:condition_remove("super_saiyan_1"), true)
  t:eq(ch:der_total("powerlevel"), 1000)
end)

return test:run()
