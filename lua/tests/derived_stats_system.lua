local test = require("lua.test").new()
local dbat = require("dbat")

local function mob()
  return dbat.mob_protos.by_id(1):spawn(dbat.rooms.by_id(1))
end

test:case("derived definitions are registered", function(t)
  local powerlevel = dbat.get("derived", "powerlevel")
  t:assert(powerlevel ~= nil, "powerlevel derived stat should exist")
  t:eq(powerlevel.name, "Power Level")
end)

test:case("derived base and total follow base stat", function(t)
  local ch = mob()
  ch:stat_set("strength", 25)
  t:eq(ch:der_base("strength"), 25)
  t:eq(ch:der_total("strength"), 25)

  ch:stat_set("powerlevel", 1000)
  t:eq(ch:der_base("powerlevel"), 1000)
  t:eq(ch:der_total("powerlevel"), 1000)
end)

test:case("condition modifiers affect derived totals", function(t)
  local ch = mob()
  ch:stat_set("powerlevel", 1000)
  t:eq(ch:der_total("powerlevel"), 1000)

  t:eq(ch:condition_apply_number("kaioken", "level", 2), true)
  t:eq(ch:condition_number_get("kaioken", "level"), 2)
  t:eq(ch:der_total("powerlevel"), 1200)

  t:eq(ch:condition_remove("kaioken"), true)
  t:eq(ch:der_total("powerlevel"), 1000)
end)

return test:run()
