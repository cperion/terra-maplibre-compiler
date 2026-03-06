-- FILE CONTEXT: New deterministic JSON writer utility for canonical dumps. AI!

-- Create a small module with `encode(value)` that serializes Lua tables to JSON deterministically: object keys sorted lexicographically; arrays emitted in index order; proper escaping for strings and support for numbers/booleans/null. This only needs to support current compiler data types. AI!-- JSON utility module for deterministic serialization
-- Encodes Lua tables to JSON with sorted keys for canonical output

local M = {}

local function escape_string(s)
    local result = {}
    for i = 1, #s do
        local c = s:sub(i, i)
        local code = string.byte(c)
        if c == '"' then
            table.insert(result, '\\"')
        elseif c == '\\' then
            table.insert(result, '\\\\')
        elseif c == '\b' then
            table.insert(result, '\\b')
        elseif c == '\f' then
            table.insert(result, '\\f')
        elseif c == '\n' then
            table.insert(result, '\\n')
        elseif c == '\r' then
            table.insert(result, '\\r')
        elseif c == '\t' then
            table.insert(result, '\\t')
        elseif code < 32 then
            table.insert(result, string.format('\\u%04x', code))
        else
            table.insert(result, c)
        end
    end
    return table.concat(result)
end

local function get_sorted_keys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

local function encode_value(value, indent_level)
    indent_level = indent_level or 0
    
    if value == nil then
        return "null"
    elseif type(value) == "boolean" then
        return value and "true" or "false"
    elseif type(value) == "number" then
        return tostring(value)
    elseif type(value) == "string" then
        return '"' .. escape_string(value) .. '"'
    elseif type(value) == "table" then
        -- Detect if this is an array or object
        local is_array = true
        local max_index = 0
        for k in pairs(value) do
            if type(k) ~= "number" then
                is_array = false
                break
            end
            if k > max_index then
                max_index = k
            end
        end
        
        -- Check for sparse arrays (treat as object if sparse)
        if is_array then
            for i = 1, max_index do
                if value[i] == nil then
                    is_array = false
                    break
                end
            end
        end
        
        if is_array and max_index > 0 then
            -- Encode as array
            local items = {}
            for i = 1, max_index do
                table.insert(items, encode_value(value[i], indent_level + 1))
            end
            return "[" .. table.concat(items, ", ") .. "]"
        else
            -- Encode as object
            local keys = get_sorted_keys(value)
            if #keys == 0 then
                return "{}"
            end
            local items = {}
            for _, k in ipairs(keys) do
                local encoded_value = encode_value(value[k], indent_level + 1)
                table.insert(items, '"' .. escape_string(tostring(k)) .. '": ' .. encoded_value)
            end
            return "{" .. table.concat(items, ", ") .. "}"
        end
    else
        return "null"
    end
end

function M.encode(value)
    return encode_value(value, 0)
end

return M
