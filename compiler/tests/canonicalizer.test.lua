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
    assert(res.style.layers[1].minzoom == 0)
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

local function test_no_mutation_of_input()
    local spec = {
        version = 1,
        style = {
            layers = {
                { id = "layer1", type = "fill", paint = { ["fill-color"] = "#fff" } }
            },
            sources = {}
        }
    }
    
    -- Store original references
    local orig_layer = spec.style.layers[1]
    local orig_paint = spec.style.layers[1].paint
    
    -- Canonicalize
    local canonical = canonicalizer.canonicalize(spec)
    
    -- Verify input spec is unchanged
    assert(spec.style.layers[1] == orig_layer, "Layer table was mutated")
    assert(spec.style.layers[1].paint == orig_paint, "Paint table was mutated")
    
    -- Verify canonical is different
    assert(canonical.style.layers[1] ~= orig_layer, "Canonical should be a new table")
    assert(canonical.style.layers[1].paint ~= orig_paint, "Canonical paint should be a new table")
    
    print("PASS: test_no_mutation_of_input")
end

local function test_source_normalization()
    local spec = {
        version = 1,
        sources = {
            water = { type = "vector", url = "mapbox://water" }
        },
        style = {
            sources = {
                land = { type = "vector", url = "mapbox://land" }
            },
            layers = {}
        }
    }
    
    local canonical = canonicalizer.canonicalize(spec)
    
    -- Both sources should be present
    assert(canonical.style.sources.water, "Top-level source 'water' not merged")
    assert(canonical.style.sources.land, "Style source 'land' not present")
    
    print("PASS: test_source_normalization")
end

local function test_source_precedence()
    local spec = {
        version = 1,
        sources = {
            roads = { type = "vector", url = "mapbox://old-roads" }
        },
        style = {
            sources = {
                roads = { type = "vector", url = "mapbox://new-roads" }
            },
            layers = {}
        }
    }
    
    local canonical = canonicalizer.canonicalize(spec)
    
    -- style.sources should take precedence
    assert(canonical.style.sources.roads.url == "mapbox://new-roads", "style.sources should override top-level sources")
    
    print("PASS: test_source_precedence")
end

test_valid_spec()
test_missing_version()
test_missing_layer_id()
test_no_mutation_of_input()
test_source_normalization()
test_source_precedence()
