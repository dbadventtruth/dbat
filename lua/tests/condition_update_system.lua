local test = require("lua.test").new()
local dbat = require("dbat")
local Condition = require("lua.characters.conditions")

local function mob()
  return dbat.mob_protos.by_id(1):spawn(dbat.rooms.by_id(1))
end

-- Minimal test condition wrapped so dispatch_event is available
local test_cond_def = Condition.wrap({ id = "test_expire_hook" })
dbat.characters.registry.conditions.test_expire_hook = test_cond_def

test:case("remaining_ms returns -1 when no expire event scheduled", function(t)
  local ch = mob()

  t:eq(ch:condition_apply("test_expire_hook"), true)
  local cond = ch:condition("test_expire_hook")

  t:eq(cond:remaining_ms(), -1)
  t:eq(cond:remaining_secs(), -1)

  ch:extract()
end)

test:case("schedule_expire sets remaining time", function(t)
  local ch = mob()

  t:eq(ch:condition_apply("test_expire_hook"), true)
  local cond = ch:condition("test_expire_hook")

  cond:schedule_expire(5)

  local secs = cond:remaining_secs()
  t:assert(secs >= 4 and secs <= 5, "remaining_secs should be ~5, got " .. tostring(secs))

  local ms = cond:remaining_ms()
  t:assert(ms >= 4000 and ms <= 5001, "remaining_ms should be ~5000, got " .. tostring(ms))

  ch:extract()
end)

test:case("schedule_expire replaces previous expire event", function(t)
  local ch = mob()

  t:eq(ch:condition_apply("test_expire_hook"), true)
  local cond = ch:condition("test_expire_hook")

  cond:schedule_expire(60)
  t:assert(cond:remaining_secs() >= 59, "should have ~60s remaining")

  cond:schedule_expire(3)
  local secs = cond:remaining_secs()
  t:assert(secs >= 2 and secs <= 3, "rescheduled to ~3s, got " .. tostring(secs))

  ch:extract()
end)

test:case("condition_remove cancels expire event", function(t)
  local ch = mob()

  t:eq(ch:condition_apply("test_expire_hook"), true)
  local cond = ch:condition("test_expire_hook")
  cond:schedule_expire(60)
  t:assert(cond:remaining_secs() >= 59, "expire event should be pending")

  ch:condition_remove("test_expire_hook")
  t:eq(ch:condition_has("test_expire_hook"), false)

  ch:extract()
end)

test:case("dispatch_event expire removes condition", function(t)
  local ch = mob()

  t:eq(ch:condition_apply("test_expire_hook"), true)
  local cond = ch:condition("test_expire_hook")

  t:eq(ch:condition_has("test_expire_hook"), true)
  test_cond_def:dispatch_event(ch, cond, "expire")
  t:eq(ch:condition_has("test_expire_hook"), false)

  ch:extract()
end)

test:case("dispatch_event expire no-ops when condition already removed", function(t)
  local ch = mob()

  t:eq(ch:condition_apply("test_expire_hook"), true)
  local cond = ch:condition("test_expire_hook")
  ch:condition_remove("test_expire_hook")

  -- Should not error even though condition is gone
  test_cond_def:dispatch_event(ch, cond, "expire")
  t:eq(ch:condition_has("test_expire_hook"), false)

  ch:extract()
end)

return test:run()
