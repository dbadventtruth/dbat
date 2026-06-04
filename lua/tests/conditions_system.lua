local test = require("lua.test").new()
local dbat = require("dbat")

local function mob()
  return dbat.mob_protos.by_id(1):spawn(dbat.rooms.by_id(1))
end

test:case("condition definitions expose tags", function(t)
  local bless = dbat.get("conditions", "bless")
  t:assert(bless ~= nil, "bless condition should be registered")
  t:eq(dbat.condition_has_tag("bless", "blessing"), true)
  t:eq(dbat.condition_has_tag("bless", "missing_tag"), false)
end)

test:case("condition apply variables stores numbers and strings", function(t)
  local ch = mob()
  t:eq(ch:condition_has("bless"), false)

  t:eq(ch:condition_apply_variables("bless", { level = 12 }, { source = "test-suite" }), true)
  t:eq(ch:condition_has("bless"), true)
  t:eq(ch:condition_has_tag("lifeforce_bonus"), true)

  local condition = ch:condition("bless")
  t:assert(condition ~= nil, "condition handle should exist")
  t:eq(condition:id(), "bless")
  t:eq(condition:number_get("level"), 12)
  t:eq(condition:string_get("source"), "test-suite")

  t:eq(condition:number_mod("level", 3), 15)
  t:eq(ch:condition_number_get("bless", "level"), 15)
  t:eq(ch:condition_string_set("bless", "source", "changed"), true)
  t:eq(condition:string_get("source"), "changed")
end)

test:case("condition removal clears active tags", function(t)
  local ch = mob()
  t:eq(ch:condition_apply("bless"), true)
  t:eq(ch:condition_has("bless"), true)

  t:eq(ch:condition_remove("bless", "test cleanup"), true)
  t:eq(ch:condition_has("bless"), false)
  t:eq(ch:condition_has_tag("lifeforce_bonus"), false)
  t:eq(ch:condition("bless"), nil)
end)

return test:run()
