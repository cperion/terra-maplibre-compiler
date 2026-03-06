-- Canonicalizer module
-- Transforms input spec into canonical form without mutating caller input

local M = {}

local function copy_deep(value)
    if type(value) == "table" then
        local result = {}
        for k, v in pairs(value) do
            result[k] = copy_deep(v)
        end
        return result
    else
        return value
    end
end

local function canonicalize_layer(layer)
    -- Create a fresh table for the canonical layer
    local canonical_layer = {
        id = layer.id,
        type = layer.type,
        source = layer.source,
        ["source-layer"] = layer["source-layer"],
        minzoom = layer.minzoom or 0,
        maxzoom = layer.maxzoom or 24,
        paint = copy_deep(layer.paint or {}),
        layout = copy_deep(layer.layout or {})
    }
    
    -- Preserve any other fields from original layer
    for k, v in pairs(layer) do
        if not canonical_layer[k] then
            canonical_layer[k] = copy_deep(v)
        end
    end
    
    return canonical_layer
end

function M.canonicalize(spec)
    if not spec.version then
        error("Spec missing version")
    end
    
    local canonical = {}
    canonical.version = spec.version
    
    -- Initialize style section
    canonical.style = {
        layers = {},
        sources = {}
    }
    
    -- Normalize sources from both locations
    -- First add from top-level 'sources', then from 'style.sources' (which takes precedence)
    if spec.sources then
        for name, source in pairs(spec.sources) do
            canonical.style.sources[name] = copy_deep(source)
        end
    end
    
    if spec.style and spec.style.sources then
        for name, source in pairs(spec.style.sources) do
            canonical.style.sources[name] = copy_deep(source)
        end
    end
    
    -- Canonicalize layers with guaranteed fields
    if spec.style and spec.style.layers then
        for i, layer in ipairs(spec.style.layers) do
            if not layer.id then
                error("Layer at index " .. i .. " missing id")
            end
            if not layer.type then
                error("Layer " .. layer.id .. " missing type")
            end
            
            table.insert(canonical.style.layers, canonicalize_layer(layer))
        end
    end
    
    -- Validate sources
    for name, source in pairs(canonical.style.sources) do
        if not source.type then
            error("Source " .. name .. " missing type")
        end
    end
    
    -- Pass through other top-level blocks with defaults
    canonical.schema = copy_deep(spec.schema or {})
    canonical.assets = copy_deep(spec.assets or {})
    canonical.interaction = copy_deep(spec.interaction or {})
    canonical.target = copy_deep(spec.target or {})
    canonical.constraints = copy_deep(spec.constraints or {})
    canonical.build = copy_deep(spec.build or {})
    
    return canonical
end

return M
