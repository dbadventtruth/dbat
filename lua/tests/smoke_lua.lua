local test = require("lua.test").new()
local dbat = require("dbat")

test:case("lua registry loaded", function(t)
  t:assert(dbat.characters ~= nil, "characters namespace should exist")
  t:assert(dbat.test.loaded_lua_entries() > 0, "expected normal Lua entries to be loaded")
end)

test:case("number formatting helper works", function(t)
  t:eq(dbat.format_number(1234567), "1,234,567")
end)

return test:run()
