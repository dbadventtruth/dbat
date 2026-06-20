local Condition = {}
Condition.__index = Condition

function Condition.wrap(def)
  def.tags           = def.tags           or {}
  def.exclusive_tags = def.exclusive_tags or {}
  def.persistent     = def.persistent     ~= nil and def.persistent     or false
  def.stackable      = def.stackable      ~= nil and def.stackable      or false
  return setmetatable(def, Condition)
end

function Condition:has_tag(tag)
  for _, t in ipairs(self.tags) do
    if t == tag then return true end
  end
  return false
end

function Condition:apply_modifiers(ch, instance)
  if not self.modifiers then return {} end
  return self.modifiers(ch, instance) or {}
end

function Condition:dispatch_event(ch, instance, event)
  if self.on_event then
    self.on_event(ch, instance, event)
  end
  if event == "expire" and ch:condition_has(self.id) then
    ch:condition_remove(self.id, "expired")
  end
end

return Condition
