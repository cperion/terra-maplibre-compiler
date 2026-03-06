-- FILE CONTEXT: New module that validates parsed input specs and returns structured errors without throwing by default. AI!

-- Create a validator module with API:
- `validate(spec) -> ok:boolean, errors:array`
- `assert_valid(spec) -> true or throws with joined human-readable message`
Each error should include at least a readable string message; include path-ish prefixes like `style.layers[2].source` where practical. AI!

-- Implement all minimum validation rules from context. Ensure duplicate layer IDs are caught. Ensure unknown source references are caught for non-background layers. AI!

-- Accept both source locations (`spec.style.sources` and `spec.sources`) for validation. When both exist, treat merged view as available sources, with `style.sources` taking precedence on conflicts. AI!-- Spec validator module
-- Validates parsed input specs and returns structured errors

local M = {}

local function add_error(errors, message, path)
    path = path or ""
    local full_msg = path ~= "" and (path .. ": " .. message) or message
    table.insert(errors, full_msg)
end

local function validate_zoom(value, path, errors)
    if type(value) ~= "number" then
        add_error(errors, "zoom value must be a number", path)
        return false
    end
    if value < 0 or value > 24 then
        add_error(errors, "zoom value must be between 0 and 24", path)
        return false
    end
    return true
end

local function validate_layer(layer, layer_idx, sources, errors)
    local path = "style.layers[" .. layer_idx .. "]"
    
    if not layer.id then
        add_error(errors, "layer missing required field 'id'", path)
    elseif type(layer.id) ~= "string" then
        add_error(errors, "layer 'id' must be a string", path)
    end
    
    if not layer.type then
        add_error(errors, "layer missing required field 'type'", path)
    elseif type(layer.type) ~= "string" then
        add_error(errors, "layer 'type' must be a string", path)
    else
        local valid_types = {background = true, fill = true, line = true, circle = true, symbol = true}
        if not valid_types[layer.type] then
            add_error(errors, "layer 'type' '" .. layer.type .. "' is not supported", path)
        end
    end
    
    -- Background layers don't need source
    if layer.type ~= "background" then
        if not layer.source then
            add_error(errors, "layer missing required field 'source' for type '" .. (layer.type or "?") .. "'", path)
        elseif type(layer.source) == "string" then
            if not sources[layer.source] then
                add_error(errors, "layer references unknown source '" .. layer.source .. "'", path)
            end
        end
    end
    
    if layer.minzoom then
        validate_zoom(layer.minzoom, path .. ".minzoom", errors)
    end
    
    if layer.maxzoom then
        validate_zoom(layer.maxzoom, path .. ".maxzoom", errors)
    end
    
    if layer.minzoom and layer.maxzoom then
        if layer.minzoom > layer.maxzoom then
            add_error(errors, "minzoom (" .. layer.minzoom .. ") cannot be greater than maxzoom (" .. layer.maxzoom .. ")", path)
        end
    end
end

function M.validate(spec)
    local errors = {}
    
    if not spec.version then
        add_error(errors, "spec missing required field 'version'")
    elseif type(spec.version) ~= "number" then
        add_error(errors, "spec 'version' must be a number")
    end
    
    local style = spec.style or {}
    local layers = style.layers or {}
    
    -- Collect all available sources
    local sources = {}
    
    -- Add sources from top-level 'sources' field
    if spec.sources then
        for name, source in pairs(spec.sources) do
            sources[name] = source
        end
    end
    
    -- Add sources from style.sources (overrides top-level on conflict)
    if style.sources then
        for name, source in pairs(style.sources) do
            sources[name] = source
        end
    end
    
    -- Validate layers
    local layer_ids = {}
    for i, layer in ipairs(layers) do
        if layer.id then
            if layer_ids[layer.id] then
                add_error(errors, "duplicate layer id '" .. layer.id .. "'", "style.layers[" .. i .. "]")
            else
                layer_ids[layer.id] = true
            end
        end
        validate_layer(layer, i, sources, errors)
    end
    
    local ok = #errors == 0
    return ok, errors
end

function M.assert_valid(spec)
    local ok, errors = M.validate(spec)
    if not ok then
        local header = "Spec validation failed:"
        local message = header
        for _, err in ipairs(errors) do
            message = message .. "\n  " .. err
        end
        error(message)
    end
    return true
end

return M
