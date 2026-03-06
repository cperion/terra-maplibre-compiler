# CURRENT TASK

## Global Context
<!-- Phase 3-4 Complete: Build end-to-end working demo. Goals: 1) Connect compiler pipeline in main.lua, 2) Create HTML demo with canvas, 3) Generate minimal Wasm module via Terra, 4) Add unit tests for host and compiler, 5) Create demo assets. This batch creates a working "hello world" map renderer. AI! -->

## Progress
<!-- KEEP THIS UPDATED: Check off items as you complete them -->
- [ ] Connect the full compiler pipeline: require all modules (parser, canonicalizer, schema_builder, layer_planner, expression_lowerer, specializer, shader_gen, emitter). In main(), call each stage in order: parse_spec -> canonicalize -> build_schema -> plan_layers -> lower_expressions -> specialize -> generate_shaders -> emit. Add progress logging and error handling.
- [ ] Create Terra module that generates Wasm. Define module header with magic 0x54455252. Export init(), frame(timestamp), resize(w,h,dpr), pointer_move/down/up, wheel, key_event functions. Import host functions: now_ms, log, request_frame, canvas_size, submit_commands, fetch_start, resource_release. Allocate linear memory with frame arena and command stream arena.
- [ ] Implement command stream builder in Terra. Functions: begin_frame(), end_frame(), clear(r,g,b,a,depth,stencil,flags), create_buffer(id,size), upload_buffer(id,offset,ptr,len), bind_vertex_buffer(slot,id,stride,offset), draw_indexed(mode,count,type,offset). Write commands to frame arena memory.
- [ ] Implement basic renderer in Terra. State: current viewport, zoom, center. Functions: render_background(color) - clear screen, render_layer(layer_id) - execute draw calls. Generate command stream for each frame.
- [ ] Create HTML demo page with full-screen canvas, script imports from host/js/index.js, usage example loading map.wasm. Add simple controls: mouse pan/zoom. Display FPS counter. Include error handling and loading states.
- [ ] CSS for demo page: full-screen canvas, overlay for controls, FPS counter in corner, loading spinner. Make it look polished.
- [ ] Simple map spec for demo: single background layer with dark color, minimal constraints, targeting WebGL2/Wasm. Use the spec format from shared/schemas.
- [ ] Unit tests for CommandInterpreter using Node.js built-in test or assert module. Mock WebGL context and memory. Test: command stream validation, each opcode execution, resource management, error handling.
- [ ] Unit tests for ResourceTable and ResourceManager. Test: create, get, set, delete operations, ID generation, clearing.
- [ ] Unit tests for parser module. Test: valid JSON parsing, file not found error, JSON syntax error handling, required fields validation.
- [ ] Unit tests for canonicalizer. Test: valid spec passes, missing version error, missing layer id error, default values applied, layer type validation.
- [ ] Shell script to build demo: 1) Run compiler on examples/demo/map-spec.json, 2) Output to examples/demo/map.wasm, 3) Start local HTTP server for testing.
- [ ] Create package.json in root for npm workspaces. Include: name 'terra-maplibre-compiler', scripts for test/host, test/compiler, build, serve. Set type: module for ESM.

## Files Being Edited
- compiler/main.lua
- compiler/terra/wasm_module.t
- compiler/terra/command_stream.t
- compiler/terra/renderer.t
- examples/demo/index.html
- examples/demo/style.css
- examples/demo/map-spec.json
- host/tests/command-interpreter.test.js
- host/tests/resource-tables.test.js
- compiler/tests/parser.test.lua
- compiler/tests/canonicalizer.test.lua
- scripts/build-demo.sh
- package.json

## Context Files
- compiler/main.lua
- compiler/config.lua
- shared/abi/browser-host-abi.md
- shared/abi/command-stream.md
- host/js/host.js
- host/js/command-interpreter.js
- examples/minimal/spec.json
