-- Shader generator

local M = {}

function M.generate_vertex_shader(layer)
    -- Simplified templates for v0
    local src = "#version 300 es\n"
    src = src .. "in vec2 a_pos;\n"
    src = src .. "uniform mat4 u_matrix;\n"
    src = src .. "void main() {\n"
    src = src .. "  gl_Position = u_matrix * vec4(a_pos, 0.0, 1.0);\n"
    src = src .. "}\n"
    return src
end

function M.generate_fragment_shader(layer)
    local src = "#version 300 es\n"
    src = src .. "precision mediump float;\n"
    src = src .. "out vec4 outColor;\n"
    src = src .. "uniform vec4 u_color;\n"
    src = src .. "void main() {\n"
    if layer.type == "circle" then
        -- Simple circle test
        src = src .. "  vec2 coord = gl_PointCoord - vec2(0.5);\n"
        src = src .. "  if(length(coord) > 0.5) discard;\n"
    end
    src = src .. "  outColor = u_color;\n"
    src = src .. "}\n"
    return src
end

return M
