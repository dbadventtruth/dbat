local test = require("lua.test").new()
local utils = require("lua.libs.utils")

test:case("partial_match prefers exact match", function(t)
  local values = { "sword", "swordsman", "swo" }

  t:eq(utils.partial_match(values, "sword"), "sword")
end)

test:case("partial_match picks shortest prefix match", function(t)
  local values = { "swordsman", "sword", "swo" }

  t:eq(utils.partial_match(values, "sw"), "swo")
end)

test:case("partial_match is case-insensitive by default", function(t)
  local values = { "Namek", "Saiyan" }

  t:eq(utils.partial_match(values, "nam"), "Namek")
end)

test:case("partial_match supports case-sensitive option", function(t)
  local values = { "Namek", "nameless" }

  t:eq(utils.partial_match(values, "nam", { case = true }), "nameless")
end)

test:case("partial_matches returns all exact matches or all prefixes", function(t)
  local values = { "catapult", "cat", "catalog", "dog" }
  local prefixes = utils.partial_matches(values, "ca")

  t:eq(#prefixes, 3)
  t:eq(prefixes[1], "cat")
  t:eq(prefixes[2], "catalog")
  t:eq(prefixes[3], "catapult")

  local exact = utils.partial_matches({ "cat", "cat", "catalog" }, "cat")
  t:eq(#exact, 2)
  t:eq(exact[1], "cat")
  t:eq(exact[2], "cat")
end)

test:case("partial_match supports object string function", function(t)
  local values = {
    { name = "apple" },
    { name = "apricot" },
    { name = "ape" },
  }
  local result = utils.partial_match(values, "ap", {
    str_func = function(value)
      return value.name
    end,
  })

  t:eq(result.name, "ape")
end)

test:case("partial_matches returns empty table with no match", function(t)
  local result = utils.partial_matches({ "one", "two" }, "z")

  t:eq(#result, 0)
end)

test:case("partial_match multi mode delegates to partial_matches", function(t)
  local result = utils.partial_match({ "one", "only", "two" }, "on", { mode = "multi" })

  t:eq(#result, 2)
  t:eq(result[1], "one")
  t:eq(result[2], "only")
end)

return test:run()
