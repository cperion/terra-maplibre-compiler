-- Parser module for map specs

local M = {}

-- Since we are in a Lua environment, we might rely on a JSON library.
-- For this environment (Terra/LuaJIT), we'll assume a `json` module is available 
-- or implement a very simple dummy one if not. 
-- In a real repo we'd include 'dkjson' or similar. 
-- For now, we'll try to require 'json' or 'cjson' if available, otherwise mock it or fail.

local json
pcall(function() json = require("cjson") end)
if not json then
    pcall(function() json = require("dkjson") end)
end

-- If still no JSON, provide a minimal mock that errors (or relies on external tool)
if not json then
    json = {
        decode = function(str) 
            error("No JSON library found (cjson or dkjson needed)") 
        end
    }
end


function M.parse_spec(filepath)
    local f = io.open(filepath, "r")
    if not f then
        return nil, "File not found: " .. filepath
    end

    local content = f:read("*all")
    f:close()

    local success, result = pcall(json.decode, content)
    if not success then
        return nil, "JSON parse error: " .. tostring(result)
    end

    return result
end

return M
