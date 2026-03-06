-- Schema builder

local M = {}

-- Basic type sizes/alignments
local TYPE_INFO = {
    float = { size = 4, align = 4 },
    int   = { size = 4, align = 4 },
    bool  = { size = 4, align = 4 }, -- treated as int for simplicity in layout
    color = { size = 16, align = 16 }, -- vec4
    vec2  = { size = 8, align = 8 },
    vec3  = { size = 12, align = 16 }, -- std140 padding
    vec4  = { size = 16, align = 16 }
}

function M.build(canonical_spec)
    local schema = {
        sources = {},
        attributes = {}
    }

    -- Process sources from spec
    for name, source_def in pairs(canonical_spec.style.sources) do
        local source_schema = {
            id = name,
            type = source_def.type,
            layers = {}
        }
        
        -- If spec provided explicit schema (it should in the full system), use it.
        -- Otherwise, we infer from usage (not implemented here, assuming explicit schema provided in 'schema' block of spec or embedded).
        -- For v0, let's assume the spec has a top-level 'schema' object matching the sources.
        
        if canonical_spec.schema and canonical_spec.schema[name] then
            for layer_name, layer_def in pairs(canonical_spec.schema[name]) do
                local layer_schema = {
                    name = layer_name,
                    geometry = layer_def.geometry,
                    properties = {}
                }
                
                -- Calculate offsets for packed attributes if we were building a packed struct
                -- For now, we just catalog the types.
                for prop_name, prop_def in pairs(layer_def.properties) do
                    layer_schema.properties[prop_name] = {
                        type = prop_def.type,
                        default = prop_def.default
                    }
                end
                
                source_schema.layers[layer_name] = layer_schema
            end
        end
        
        schema.sources[name] = source_schema
    end

    return schema
end

return M
