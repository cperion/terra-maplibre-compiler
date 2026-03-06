-- Spec validator module
-- Validates parsed input specs and returns structured errors

local M = {}

local function is_integer(n)
    return type(n) == "number" and n % 1 == 0
end

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

    if type(layer) ~= "table" then
        add_error(errors, "layer must be an object", path)
        return
    end
    
    if layer.id == nil then
        add_error(errors, "layer missing required field 'id'", path)
    elseif type(layer.id) ~= "string" or layer.id == "" then
        add_error(errors, "layer 'id' must be a string", path)
    end
    
    if not layer.type then
        add_error(errors, "layer missing required field 'type'", path)
    elseif type(layer.type) ~= "string" then
        add_error(errors, "layer 'type' must be a string", path)
    else
        local valid_types = { background = true, fill = true, line = true, circle = true }
        if not valid_types[layer.type] then
            add_error(errors, "layer 'type' '" .. layer.type .. "' is not supported", path)
        end
    end
    
    -- Background layers don't need source
    if layer.type ~= "background" then
        if layer.source == nil then
            add_error(errors, "layer missing required field 'source' for type '" .. (layer.type or "?") .. "'", path)
        elseif type(layer.source) ~= "string" or layer.source == "" then
            add_error(errors, "layer 'source' must be a non-empty string", path)
        else
            if not sources[layer.source] then
                add_error(errors, "layer references unknown source '" .. layer.source .. "'", path)
            end
        end
    end

    if layer["source-layer"] ~= nil then
        if type(layer["source-layer"]) ~= "string" or layer["source-layer"] == "" then
            add_error(errors, "'source-layer' must be a non-empty string when provided", path .. ".source-layer")
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

    if type(spec) ~= "table" then
        add_error(errors, "spec must be an object")
        return false, errors
    end
    
    if spec.version == nil then
        add_error(errors, "spec missing required field 'version'")
    elseif not is_integer(spec.version) or spec.version < 1 then
        add_error(errors, "spec 'version' must be an integer >= 1")
    end

    if type(spec.style) ~= "table" then
        add_error(errors, "spec missing required object 'style'", "style")
    end

    local style = type(spec.style) == "table" and spec.style or {}

    if style.layers == nil then
        add_error(errors, "style missing required array 'layers'", "style.layers")
    elseif type(style.layers) ~= "table" then
        add_error(errors, "style 'layers' must be an array", "style.layers")
    end

    local layers = type(style.layers) == "table" and style.layers or {}
    
    -- Collect all available sources
    local sources = {}
    
    -- Add sources from top-level 'sources' field
    if spec.sources ~= nil and type(spec.sources) ~= "table" then
        add_error(errors, "top-level 'sources' must be an object", "sources")
    elseif spec.sources then
        for name, source in pairs(spec.sources) do
            sources[name] = source
        end
    end
    
    -- Add sources from style.sources (overrides top-level on conflict)
    if style.sources ~= nil and type(style.sources) ~= "table" then
        add_error(errors, "style 'sources' must be an object", "style.sources")
    elseif style.sources then
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
