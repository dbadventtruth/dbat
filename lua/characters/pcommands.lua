local M = {}
M.__index = M

local sorted = nil

function M.wrap(def)
    def.aliases  = def.aliases  or {}
    def.priority = def.priority or 0
    sorted = nil  -- invalidate on each new registration
    return setmetatable(def, M)
end

function M.sorted_list()
    if not sorted then
        local dbat = require("dbat")
        local list = {}
        for _, def in pairs(dbat.characters.registry.pcommands or {}) do
            list[#list + 1] = def
        end
        table.sort(list, function(a, b) return (a.priority or 0) > (b.priority or 0) end)
        sorted = list
    end
    return sorted
end

return M
