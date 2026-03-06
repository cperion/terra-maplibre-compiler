-- Canonicalizer module

local M = {}

function M.canonicalize(spec)
    local canonical = {}
    
    -- Ensure version
    if not spec.version then
        error("Spec missing version")
    end
    canonical.version = spec.version

    -- Style normalization
    canonical.style = spec.style or {}
    canonical.style.layers = canonical.style.layers or {}
    canonical.style.sources = canonical.style.sources or {}
    
    -- Expand shorthands and set defaults for layers
    for i, layer in ipairs(canonical.style.layers) do
        if not layer.id then
            error("Layer at index " .. i .. " missing id")
        end
        if not layer.type then
            error("Layer " .. layer.id .. " missing type")
        end
        
        -- Defaults
        layer.paint = layer.paint or {}
        layer.layout = layer.layout or {}
        layer.minzoom = layer.minzoom or 0
        layer.maxzoom = layer.maxzoom or 24
    end

    -- Canonicalize sources
    for name, source in pairs(canonical.style.sources) do
        if not source.type then
            error("Source " .. name .. " missing type")
        end
    end

    -- Pass through other top-level fields
    canonical.schema = spec.schema or {}
    canonical.assets = spec.assets or {}
    canonical.interaction = spec.interaction or {}
    canonical.target = spec.target or {}
    canonical.constraints = spec.constraints or {}
    canonical.build = spec.build or {}

    return canonical
end

return M
