-- Unit tests for spec validator

local parser = require("compiler.lua.parser")
local spec_validator = require("compiler.lua.spec-validator")

local function test_valid_background()
    local spec = {
        version = 1,
        style = {
            layers = {
                { id = "bg", type = "background", paint = { ["background-color"] = "#fff" } }
            }
        }
    }
    local ok, errors = spec_validator.validate(spec)
    assert(ok, "Valid background spec should pass")
    assert(#errors == 0, "Should have no errors")
    print("PASS: test_valid_background")
end

local function test_invalid_version_type()
    local spec = {
        version = 1.5,
        style = {
            layers = {
                { id = "bg", type = "background" }
            }
        }
    }
    local ok, errors = spec_validator.validate(spec)
    assert(not ok, "Non-integer version should fail")
    assert(#errors > 0, "Should have errors")
    print("PASS: test_invalid_version_type")
end

local function test_missing_style()
    local spec = {
        version = 1
    }
    local ok, errors = spec_validator.validate(spec)
    assert(not ok, "Missing style should fail")
    assert(#errors > 0, "Should have errors")
    print("PASS: test_missing_style")
end

local function test_duplicate_layer_ids()
    local spec = {
        version = 1,
        style = {
            layers = {
                { id = "layer1", type = "fill", source = "src1" },
                { id = "layer1", type = "fill", source = "src1" }
            }
        }
    }
    local ok, errors = spec_validator.validate(spec)
    assert(not ok, "Duplicate layer IDs should fail validation")
    assert(#errors > 0, "Should have errors")
    local has_dup_error = false
    for _, err in ipairs(errors) do
        if string.find(err, "duplicate") then
            has_dup_error = true
            break
        end
    end
    assert(has_dup_error, "Should have duplicate layer ID error")
    print("PASS: test_duplicate_layer_ids")
end

local function test_unsupported_layer_type()
    local spec = {
        version = 1,
        style = {
            layers = {
                { id = "layer1", type = "unknown_type" }
            }
        }
    }
    local ok, errors = spec_validator.validate(spec)
    assert(not ok, "Unsupported layer type should fail")
    assert(#errors > 0, "Should have errors")
    print("PASS: test_unsupported_layer_type")
end

local function test_missing_source_for_fill()
    local spec = {
        version = 1,
        style = {
            layers = {
                { id = "roads", type = "fill" }
            }
        }
    }
    local ok, errors = spec_validator.validate(spec)
    assert(not ok, "Missing source should fail for fill layer")
    assert(#errors > 0, "Should have errors")
    print("PASS: test_missing_source_for_fill")
end

local function test_unknown_source_reference()
    local spec = {
        version = 1,
        style = {
            sources = {
                water = { type = "vector" }
            },
            layers = {
                { id = "roads", type = "fill", source = "unknown_source" }
            }
        }
    }
    local ok, errors = spec_validator.validate(spec)
    assert(not ok, "Unknown source reference should fail")
    assert(#errors > 0, "Should have errors")
    local has_source_error = false
    for _, err in ipairs(errors) do
        if string.find(err, "unknown source") then
            has_source_error = true
            break
        end
    end
    assert(has_source_error, "Should have unknown source error")
    print("PASS: test_unknown_source_reference")
end

local function test_invalid_zoom_range()
    local spec = {
        version = 1,
        style = {
            layers = {
                { id = "bg", type = "background", minzoom = 30 }
            }
        }
    }
    local ok, errors = spec_validator.validate(spec)
    assert(not ok, "Invalid zoom range should fail")
    assert(#errors > 0, "Should have errors")
    print("PASS: test_invalid_zoom_range")
end

local function test_minzoom_greater_than_maxzoom()
    local spec = {
        version = 1,
        style = {
            layers = {
                { id = "bg", type = "background", minzoom = 15, maxzoom = 5 }
            }
        }
    }
    local ok, errors = spec_validator.validate(spec)
    assert(not ok, "minzoom > maxzoom should fail")
    assert(#errors > 0, "Should have errors")
    print("PASS: test_minzoom_greater_than_maxzoom")
end

local function test_invalid_source_layer_when_present()
    local spec = {
        version = 1,
        style = {
            sources = {
                roads_src = { type = "vector" }
            },
            layers = {
                { id = "roads", type = "line", source = "roads_src", ["source-layer"] = "" }
            }
        }
    }
    local ok, errors = spec_validator.validate(spec)
    assert(not ok, "Empty source-layer should fail")
    assert(#errors > 0, "Should have errors")
    print("PASS: test_invalid_source_layer_when_present")
end

local function test_fixture_specs()
    local minimal_path = "shared/fixtures/specs/minimal-clear.json"
    local fill_path = "shared/fixtures/specs/fill-layer.json"
    
    local minimal_spec, err1 = parser.parse_spec(minimal_path)
    if not minimal_spec then
        print("Warning: Could not load minimal-clear.json: " .. err1)
        return
    end
    
    local ok1, errors1 = spec_validator.validate(minimal_spec)
    assert(ok1, "minimal-clear.json should be valid. Errors: " .. table.concat(errors1, "; "))
    
    local fill_spec, err2 = parser.parse_spec(fill_path)
    if not fill_spec then
        print("Warning: Could not load fill-layer.json: " .. err2)
        return
    end
    
    local ok2, errors2 = spec_validator.validate(fill_spec)
    assert(ok2, "fill-layer.json should be valid. Errors: " .. table.concat(errors2, "; "))
    
    print("PASS: test_fixture_specs")
end

test_valid_background()
test_invalid_version_type()
test_missing_style()
test_duplicate_layer_ids()
test_unsupported_layer_type()
test_missing_source_for_fill()
test_unknown_source_reference()
test_invalid_zoom_range()
test_minzoom_greater_than_maxzoom()
test_invalid_source_layer_when_present()
test_fixture_specs()
