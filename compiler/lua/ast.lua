-- AST node definitions for expressions

local M = {}

function M.Literal(node_type, value)
    return { kind = "Literal", type = node_type, value = value }
end

function M.Identifier(name)
    return { kind = "Identifier", name = name }
end

function M.BinaryOp(op, left, right)
    return { kind = "BinaryOp", op = op, left = left, right = right }
end

function M.UnaryOp(op, operand)
    return { kind = "UnaryOp", op = op, operand = operand }
end

function M.Call(callee, args)
    return { kind = "Call", callee = callee, args = args }
end

function M.Member(object, property)
    return { kind = "Member", object = object, property = property }
end

function M.Conditional(test, consequent, alternate)
    return { kind = "Conditional", test = test, consequent = consequent, alternate = alternate }
end

return M
