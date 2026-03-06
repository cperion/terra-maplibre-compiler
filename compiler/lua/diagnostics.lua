-- Diagnostics and error reporting

local M = {}

M.Level = {
    ERROR = "error",
    WARNING = "warning",
    INFO = "info"
}

local diagnostics = {}

function M.add(level, msg, loc)
    table.insert(diagnostics, {
        level = level,
        message = msg,
        location = loc or { file = "unknown", line = 0, column = 0 }
    })
end

function M.error(msg, loc)
    M.add(M.Level.ERROR, msg, loc)
end

function M.warn(msg, loc)
    M.add(M.Level.WARNING, msg, loc)
end

function M.info(msg, loc)
    M.add(M.Level.INFO, msg, loc)
end

function M.has_errors()
    for _, diag in ipairs(diagnostics) do
        if diag.level == M.Level.ERROR then
            return true
        end
    end
    return false
end

function M.report()
    for _, diag in ipairs(diagnostics) do
        local loc_str = string.format("%s:%d:%d", diag.location.file, diag.location.line, diag.location.column)
        print(string.format("[%s] %s: %s", string.upper(diag.level), loc_str, diag.message))
    end
end

function M.clear()
    diagnostics = {}
end

return M
