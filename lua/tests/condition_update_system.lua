local test = require("lua.test").new()
local dbat = require("dbat")

local function mob()
  return dbat.mob_protos.by_id(1):spawn(dbat.rooms.by_id(1))
end

dbat.registry.conditions.test_update_hook = {
  id = "test_update_hook",
  on_update = function(ch, condition, ctx)
    condition:number_mod("ticks", 1)
    condition:string_set("kind", ctx.kind)
    condition:number_set("seconds", ctx.seconds)
  end,
}

dbat.registry.conditions.test_update_remove_self = {
  id = "test_update_remove_self",
  on_update = function(ch)
    ch:condition_remove("test_update_remove_self")
  end,
}

test:case("condition on_update receives update context", function(t)
  local ch = mob()

  t:eq(ch:condition_apply("test_update_hook"), true)
  ch:update("second", 1)

  local condition = ch:condition("test_update_hook")
  t:eq(condition:number_get("ticks"), 1)
  t:eq(condition:string_get("kind"), "second")
  t:eq(condition:number_get("seconds"), 1)

  ch:extract()
end)

test:case("condition update iteration tolerates self removal", function(t)
  local ch = mob()

  t:eq(ch:condition_apply("test_update_remove_self"), true)
  t:eq(ch:condition_apply("test_update_hook"), true)
  ch:update("second", 1)

  t:eq(ch:condition_has("test_update_remove_self"), false)
  t:eq(ch:condition("test_update_hook"):number_get("ticks"), 1)

  ch:extract()
end)

test:case("finite condition durations expire after updates", function(t)
  local ch = mob()

  t:eq(ch:condition_apply("test_update_hook"), true)
  local condition = ch:condition("test_update_hook")
  condition:duration_set(2)

  ch:update("second", 1)
  t:eq(ch:condition_has("test_update_hook"), true)
  t:eq(condition:duration(), 1)

  ch:update("second", 1)
  t:eq(ch:condition_has("test_update_hook"), false)

  ch:extract()
end)

return test:run()
