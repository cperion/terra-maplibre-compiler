
-- Unit tests for parser module

local parser = require("compiler.lua.parser")

-- Mock IO and JSON for testing if not present, but for now we assume environment is set up.
-- If running via terra, these should work.

local function test_file_not_found()
    local res, err = parser.parse_spec("non_existent_file.json")
    assert(res == nil)
    assert(string.find(err, "File not found"))
    print("PASS: test_file_not_found")
end

local function test_valid_json()
    -- Create temporary test file
    local fname = "test_valid.json"
    local f = io.open(fname, "w")
    f:write('{"version": 1, "style": {}}')
    f:close()

    local spec, err = parser.parse_spec(fname)
    assert(spec ~= nil, err)
    assert(spec.version == 1)
    
    os.remove(fname)
    print("PASS: test_valid_json")
end

local function test_invalid_json()
    local fname = "test_invalid.json"
    local f = io.open(fname, "w")
    f:write('{version: 1, broken}') -- Invalid JSON
    f:close()

    local spec, err = parser.parse_spec(fname)
    assert(spec == nil)
    assert(string.find(err, "JSON parse error") or string.find(err, "Expected"))
    
    os.remove(fname)
    print("PASS: test_invalid_json")
end

test_file_not_found()
test_valid_json()
test_invalid_json()
