-- Type system definitions

local M = {}

-- Primitive Types
M.Float = { kind = "Primitive", name = "float" }
M.Int = { kind = "Primitive", name = "int" }
M.Bool = { kind = "Primitive", name = "bool" }
M.String = { kind = "Primitive", name = "string" }
M.Color = { kind = "Primitive", name = "color" }

-- Vector Types
function M.Vector(component_type, size)
    return { kind = "Vector", component = component_type, size = size }
end

M.Vec2 = M.Vector(M.Float, 2)
M.Vec3 = M.Vector(M.Float, 3)
M.Vec4 = M.Vector(M.Float, 4)

-- Function Type
function M.Function(params, return_type)
    return { kind = "Function", params = params, return_type = return_type }
end

-- Layer Types
M.LayerFill = { kind = "Layer", name = "fill" }
M.LayerLine = { kind = "Layer", name = "line" }
M.LayerCircle = { kind = "Layer", name = "circle" }
M.LayerSymbol = { kind = "Layer", name = "symbol" }

return M
