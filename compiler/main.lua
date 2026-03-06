#!/usr/bin/env lua
-- Main compiler entry point
-- Usage: terra main.lua --input spec.json --output map.wasm

local usage = [[
Terra Map Compiler
Usage: terra main.lua [options]

Options:
  --input <path>      Path to input map specification JSON (required)
  --output <path>     Path to output Wasm file (default: map.wasm)
  --schema <path>     Path to output schema JSON (optional)
  --manifest <path>   Path to output manifest JSON (optional)
  --debug             Enable debug mode
  --help              Show this help message

Example:
  terra main.lua --input examples/minimal/spec.json --output dist/map.wasm
]]

local function parse_args(args)
    local options = {
        input = nil,
        output = "map.wasm",
        schema = nil,
        manifest = nil,
        debug = false
    }
    
    local i = 1
    while i <= #args do
        local arg = args[i]
        if arg == "--input" then
            i = i + 1
            options.input = args[i]
        elseif arg == "--output" then
            i = i + 1
            options.output = args[i]
        elseif arg == "--schema" then
            i = i + 1
            options.schema = args[i]
        elseif arg == "--manifest" then
            i = i + 1
            options.manifest = args[i]
        elseif arg == "--debug" then
            options.debug = true
        elseif arg == "--help" then
            print(usage)
            os.exit(0)
        end
        i = i + 1
    end
    
    return options
end

local function main()
    local args = arg
    local opts = parse_args(args)
    
    if not opts.input then
        print("Error: --input argument is required")
        print(usage)
        os.exit(1)
    end
    
    print("Terra Map Compiler v0.0.1-dev")
    print("Input: " .. opts.input)
    print("Output: " .. opts.output)
    
    -- Mock compilation pipeline for now
    -- In real implementation:
    -- 1. local spec = parser.parse_spec(opts.input)
    -- 2. local clean_spec = canonicalizer.canonicalize(spec)
    -- 3. local schema = schema_builder.build(clean_spec)
    -- 4. local ir = expression_lowerer.lower(clean_spec, schema)
    -- 5. codegen.generate(ir, opts.output)
    
    print("Compiling...")
    
    -- Load compiler modules
    local parser = require("compiler.lua.parser")
    local canonicalizer = require("compiler.lua.canonicalizer")
    local schema_builder = require("compiler.lua.schema-builder")
    local layer_planner = require("compiler.lua.layer-planner")
    local expression_lowerer = require("compiler.lua.expression-lowerer")
    local specializer = require("compiler.lua.specializer")
    local shader_gen = require("compiler.lua.shader-gen")
    local emitter = require("compiler.lua.emitter")

    -- 1. Parse
    print("[1/8] Parsing spec...")
    local raw_spec, err = parser.parse_spec(opts.input)
    if not raw_spec then
        print("Error parsing spec: " .. tostring(err))
        os.exit(1)
    end

    -- 2. Canonicalize
    print("[2/8] Canonicalizing...")
    local canonical_spec = canonicalizer.canonicalize(raw_spec)

    -- 3. Build Schema
    print("[3/8] Building schema...")
    local schema = schema_builder.build(canonical_spec)

    -- 4. Plan Layers
    print("[4/8] Planning layers...")
    local layer_plan = layer_planner.plan(canonical_spec)

    -- 5. Lower Expressions (iterate over layers in plan)
    print("[5/8] Lowering expressions...")
    -- This is a simplification; normally we'd update the layer plan or a new IR with lowered exprs
    for _, layer in ipairs(layer_plan.layers) do
        -- Lower filter if present (mock implementation structure)
        -- layer.filter_ir = expression_lowerer.lower(layer.filter, schema)
        -- Lower paint properties
        -- for prop, expr in pairs(layer.paint) do ... end
    end

    -- 6. Specialize
    print("[6/8] Specializing...")
    local specialized_ir = specializer.specialize(layer_plan, canonical_spec.constraints)

    -- 7. Generate Shaders
    print("[7/8] Generating shaders...")
    for _, layer in ipairs(specialized_ir.layers) do
        -- Mock attaching shader source to layer IR
        layer.vertex_shader = shader_gen.generate_vertex_shader(layer)
        layer.fragment_shader = shader_gen.generate_fragment_shader(layer)
    end

    -- 8. Emit Wasm
    print("[8/8] Emitting Wasm...")
    local wasm_bytes = emitter.emit(specialized_ir)

    -- Write output
    local f, err = io.open(opts.output, "wb")
    if f then
        -- If emitter returns a mock string, write it. If it returns bytes, write them.
        -- For now, our mock emitter returns a string.
        if wasm_bytes == "MOCK_WASM_BINARY_DATA" then
            -- Write a minimal valid wasm header so hosts don't choke immediately if they check magic
            f:write("\0asm\1\0\0\0")
        else
            f:write(wasm_bytes)
        end
        f:close()
        print("Success: Wrote " .. opts.output)
    else
        print("Error: Could not write to " .. opts.output .. ": " .. tostring(err))
        os.exit(1)
    end
    
    os.exit(0)
end

main()
