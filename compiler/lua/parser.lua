-- Included as context AI!
-- FILE CONTEXT: Parser already has fallback decoder; keep behavior but ensure parse errors are clear. AI!
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

local function make_minimal_json_decoder()
    local function decode(str)
        local i = 1
        local n = #str

        local function skip_ws()
            while i <= n do
                local c = str:sub(i, i)
                if c == " " or c == "\t" or c == "\r" or c == "\n" then
                    i = i + 1
                else
                    break
                end
            end
        end

        local parse_value

        local function parse_string()
            if str:sub(i, i) ~= '"' then
                error("expected string")
            end
            i = i + 1
            local out = {}
            while i <= n do
                local c = str:sub(i, i)
                if c == '"' then
                    i = i + 1
                    return table.concat(out)
                elseif c == "\\" then
                    i = i + 1
                    local esc = str:sub(i, i)
                    local map = { ['"'] = '"', ['\\'] = '\\', ['/'] = '/', b = '\b', f = '\f', n = '\n', r = '\r', t = '\t' }
                    local v = map[esc]
                    if not v then
                        error("unsupported escape sequence")
                    end
                    out[#out + 1] = v
                    i = i + 1
                else
                    out[#out + 1] = c
                    i = i + 1
                end
            end
            error("unterminated string")
        end

        local function parse_number()
            local start_i = i
            if str:sub(i, i) == "-" then
                i = i + 1
            end
            while i <= n and str:sub(i, i):match("%d") do
                i = i + 1
            end
            if str:sub(i, i) == "." then
                i = i + 1
                while i <= n and str:sub(i, i):match("%d") do
                    i = i + 1
                end
            end
            local e = str:sub(i, i)
            if e == "e" or e == "E" then
                i = i + 1
                local sign = str:sub(i, i)
                if sign == "+" or sign == "-" then
                    i = i + 1
                end
                while i <= n and str:sub(i, i):match("%d") do
                    i = i + 1
                end
            end
            local num = tonumber(str:sub(start_i, i - 1))
            if num == nil then
                error("invalid number")
            end
            return num
        end

        local function parse_literal(lit, value)
            if str:sub(i, i + #lit - 1) ~= lit then
                error("invalid literal")
            end
            i = i + #lit
            return value
        end

        local function parse_array()
            i = i + 1
            skip_ws()
            local arr = {}
            if str:sub(i, i) == "]" then
                i = i + 1
                return arr
            end
            while true do
                arr[#arr + 1] = parse_value()
                skip_ws()
                local c = str:sub(i, i)
                if c == "]" then
                    i = i + 1
                    return arr
                elseif c == "," then
                    i = i + 1
                    skip_ws()
                else
                    error("expected ',' or ']' in array")
                end
            end
        end

        local function parse_object()
            i = i + 1
            skip_ws()
            local obj = {}
            if str:sub(i, i) == "}" then
                i = i + 1
                return obj
            end
            while true do
                local key = parse_string()
                skip_ws()
                if str:sub(i, i) ~= ":" then
                    error("expected ':' in object")
                end
                i = i + 1
                skip_ws()
                obj[key] = parse_value()
                skip_ws()
                local c = str:sub(i, i)
                if c == "}" then
                    i = i + 1
                    return obj
                elseif c == "," then
                    i = i + 1
                    skip_ws()
                else
                    error("expected ',' or '}' in object")
                end
            end
        end

        parse_value = function()
            skip_ws()
            local c = str:sub(i, i)
            if c == "{" then
                return parse_object()
            elseif c == "[" then
                return parse_array()
            elseif c == '"' then
                return parse_string()
            elseif c == "-" or c:match("%d") then
                return parse_number()
            elseif c == "t" then
                return parse_literal("true", true)
            elseif c == "f" then
                return parse_literal("false", false)
            elseif c == "n" then
                return parse_literal("null", nil)
            end
            error("unexpected character")
        end

        local value = parse_value()
        skip_ws()
        if i <= n then
            error("trailing characters")
        end
        return value
    end

    return { decode = decode }
end

if not json then
    json = make_minimal_json_decoder()
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
        return nil, "JSON parse error in " .. filepath .. ": " .. tostring(result)
    end

    return result
end

return M
