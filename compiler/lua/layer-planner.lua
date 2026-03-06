-- Layer planner

local M = {}

function M.plan(canonical_spec)
    local plan = {
        layers = {},
        groups = {}
    }

    -- 1. Sort layers (Canonical spec should already have order, but we confirm)
    -- In v0, we iterate the array which preserves order.
    
    local current_group = nil
    
    for i, layer in ipairs(canonical_spec.style.layers) do
        local layer_plan = {
            id = layer.id,
            type = layer.type,
            source = layer.source,
            source_layer = layer["source-layer"],
            minzoom = layer.minzoom,
            maxzoom = layer.maxzoom,
            paint = layer.paint,
            layout = layer.layout
        }
        
        table.insert(plan.layers, layer_plan)

        -- Simple grouping strategy: group adjacent layers of same type
        -- Real strategy would check for state changes (blend mode, opacity, etc.)
        if not current_group or current_group.type ~= layer.type then
            current_group = {
                id = "group_" .. #plan.groups,
                type = layer.type,
                layers = {}
            }
            table.insert(plan.groups, current_group)
        end
        
        table.insert(current_group.layers, layer.id)
    end

    return plan
end

return M
