local function on_event(zone, kind)
  local subsystem, id, event_name = kind:match("^([^:]+):([^:]+):?(.*)$")
  event_name = (event_name and event_name ~= "") and event_name or "tick"
  if subsystem == "script" then
    if not zone:script_has(id) then return end
    local def = require("dbat").get("zone_scripts", id)
    if def and def.on_event then def.on_event(zone, zone:script(id), event_name) end
  end
end

return { on_event = on_event }
