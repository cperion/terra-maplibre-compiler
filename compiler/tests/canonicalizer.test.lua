-- Included as context AI!
-- FILE CONTEXT: Expand canonicalizer coverage for new normalization guarantees. AI!

-- Unit tests for canonicalizer

local canonicalizer = require("compiler.lua.canonicalizer")

local function test_valid_spec()
    local spec = {
        version = 1,
        style = {
            layers = {
                { id = "bg", type = "background" }
            }
        }
    }
    local res = canonicalizer.canonicalize(spec)
    assert(res.version == 1)
    assert(res.style.layers[1].minzoom == 0) -- Check defaults
    print("PASS: test_valid_spec")
end

local function test_missing_version()
    local spec = {}
    local status, err = pcall(function() canonicalizer.canonicalize(spec) end)
    assert(status == false)
    assert(string.find(err, "missing version"))
    print("PASS: test_missing_version")
end

local function test_missing_layer_id()
    local spec = {
        version = 1,
        style = {
            layers = {
                { type = "background" }
            }
        }
    }
    local status, err = pcall(function() canonicalizer.canonicalize(spec) end)
    assert(status == false)
    assert(string.find(err, "missing id"))
    print("PASS: test_missing_layer_id")
end

test_valid_spec()
test_missing_version()
test_missing_layer_id()

-- Add tests that verify canonicalizer does not mutate the input spec tables (including nested layers). AI!

-- Add tests that verify source normalization from top-level `sources` and conflict precedence where both `sources` and `style.sources` define same key. AI!