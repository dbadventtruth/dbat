local M = {}

local Runner = {}
Runner.__index = Runner

function M.new()
  return setmetatable({ cases = {}, passed = 0, failed = 0 }, Runner)
end

function Runner:case(name, fn)
  self.cases[#self.cases + 1] = { name = name, fn = fn }
end

local Assert = {}
Assert.__index = Assert

function Assert:assert(value, message)
  if not value then
    error(message or "assertion failed", 2)
  end
end

function Assert:eq(actual, expected, message)
  if actual ~= expected then
    error(message or string.format("expected %s, got %s", tostring(expected), tostring(actual)), 2)
  end
end

function Assert:ne(actual, expected, message)
  if actual == expected then
    error(message or string.format("did not expect %s", tostring(actual)), 2)
  end
end

function Assert:near(actual, expected, epsilon, message)
  epsilon = epsilon or 0.000001
  if math.abs(actual - expected) > epsilon then
    error(message or string.format("expected %s near %s", tostring(actual), tostring(expected)), 2)
  end
end

function Assert:fail(message)
  error(message or "explicit failure", 2)
end

function Runner:run()
  for _, case in ipairs(self.cases) do
    local ok, err = pcall(case.fn, setmetatable({ name = case.name }, Assert))
    if ok then
      self.passed = self.passed + 1
      print("PASS " .. case.name)
    else
      self.failed = self.failed + 1
      print("FAIL " .. case.name .. ": " .. tostring(err))
    end
  end

  print(string.format("%d passed, %d failed", self.passed, self.failed))
  return self.failed == 0
end

return M
