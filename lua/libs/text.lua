local M = {}

function M.normalize_key(value)
    return string.lower(tostring(value or "")):gsub("[^%w]+", "")
end

function M.add_commas(value)
    local dbat = require("dbat")
    return dbat.add_commas(value)
end

M.format_number = M.add_commas

return M
