-- Expression lowerer
local AST = require("compiler.lua.ast")
-- local Types = require("compiler.lua.types") -- Assuming types are needed

local M = {}

function M.lower(ast_node, schema)
    if not ast_node then return nil end

    if ast_node.kind == "Literal" then
        return { op = "const", value = ast_node.value, type = ast_node.type }
        
    elseif ast_node.kind == "Identifier" then
        -- Look up in schema/scope
        return { op = "load_var", name = ast_node.name }
        
    elseif ast_node.kind == "BinaryOp" then
        local left = M.lower(ast_node.left, schema)
        local right = M.lower(ast_node.right, schema)
        return { op = ast_node.op, left = left, right = right }
        
    elseif ast_node.kind == "UnaryOp" then
        local operand = M.lower(ast_node.operand, schema)
        return { op = ast_node.op, operand = operand }
        
    elseif ast_node.kind == "Call" then
        local args = {}
        for _, arg in ipairs(ast_node.args) do
            table.insert(args, M.lower(arg, schema))
        end
        -- Handle intrinsics like get(), has()
        if ast_node.callee.name == "get" then
            return { op = "get_prop", key = args[1] }
        end
        return { op = "call", func = ast_node.callee.name, args = args }
        
    elseif ast_node.kind == "Conditional" then
        local test = M.lower(ast_node.test, schema)
        local consequent = M.lower(ast_node.consequent, schema)
        local alternate = M.lower(ast_node.alternate, schema)
        return { op = "select", test = test, true_val = consequent, false_val = alternate }
    end

    error("Unknown AST node kind: " .. tostring(ast_node.kind))
end

return M
