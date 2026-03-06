# Terra AOT Map Compiler for Browser Wasm

## Complete Technical Specification

## 1. Purpose

This document specifies a system that compiles a declarative map specification into a single specialized WebAssembly renderer for the browser.

The system has two runtime components:

1. a **compiler service**, implemented in Terra with Lua metaprogramming, that accepts a map specification and emits a specialized Wasm module,
2. a **thin browser host**, implemented as a small JavaScript module, that creates a canvas and GPU context, instantiates the Wasm module, forwards browser events, and executes GPU commands described by the module.

The browser client does **not** interpret style expressions, perform general-purpose map rendering logic, or contain a generic map engine. All application-level map behavior is compiled ahead of time into the generated Wasm.

---

## 2. Goals

### 2.1 Primary goals

- Compile a fixed map specification into a **single-purpose Wasm renderer**.
- Eliminate runtime interpretation of map style expressions.
- Minimize client-side JavaScript to a thin platform adapter.
- Use shared Wasm memory for CPU-side data exchange between JavaScript and Wasm.
- Generate specialized shaders and render pipelines from the map specification.
- Produce deterministic, reproducible binary output from a given specification and compiler version.
- Support efficient rendering on a browser canvas with a stable host ABI.

### 2.2 Secondary goals

- Enable server-side build caching of compiled map modules.
- Support schema-aware specialization for vector tile properties.
- Support ahead-of-time validation of rendering semantics.
- Keep the browser-side runtime small enough to embed in any application.

### 2.3 Non-goals for v1

- Full runtime-equivalent compatibility with a generic MapLibre implementation.
- Arbitrary runtime restyling.
- General-purpose symbol placement in the first release.
- Arbitrary plugin execution in the browser.
- A browser client that runs without any JavaScript host glue.

---

## 3. Design principles

1. **Compile, do not interpret.**
   All style semantics that can be resolved at compile time shall be resolved at compile time.

2. **Specialize aggressively.**
   The generated module shall only contain the code paths needed for the target map specification.

3. **Constrain the runtime boundary.**
   The browser host shall provide a small, explicit ABI and no rendering policy.

4. **Use shared linear memory.**
   CPU-side buffers exchanged between JavaScript and Wasm shall be passed by offsets and lengths into shared WebAssembly memory.

5. **Prefer command streams to call-heavy imports.**
   The Wasm module should write render command buffers into memory; the host should interpret and submit them.

6. **Exploit schema knowledge.**
   Known source schemas shall be lowered into fixed property accessors and packed layouts.

7. **Make output inspectable.**
   Generated binaries, shader manifests, and compiler reports shall be debuggable and versioned.

---

## 4. System overview

### 4.1 Components

#### Compiler service
A long-lived Terra/Lua service that:
- parses input specifications,
- validates sources and schemas,
- lowers expressions into typed IR,
- performs partial evaluation and specialization,
- generates shaders,
- emits Wasm runtime code,
- assembles a final `.wasm` binary and metadata.

#### Browser host
A minimal ES module that:
- creates or receives a canvas,
- acquires a WebGL2 context in v1,
- instantiates the Wasm module,
- provisions shared memory,
- exposes imported host functions,
- forwards resize/input/network/resource events,
- reads command buffers from shared memory,
- submits commands to the GPU.

#### Generated Wasm renderer
A single-purpose module that:
- owns map state,
- performs camera transforms,
- decodes tile payloads,
- evaluates compiled style logic,
- builds buckets,
- performs visibility/culling,
- emits render commands,
- manages resource state,
- drives frame scheduling logic.

### 4.2 High-level data flow

1. User or application submits map spec to compiler service.
2. Compiler validates spec, source schema, assets, capabilities.
3. Compiler emits specialized Wasm module and optional manifest.
4. Browser host fetches `.wasm`.
5. Host creates `WebAssembly.Memory` and instantiates module.
6. Host creates GPU context and passes dimensions/capabilities to Wasm.
7. Wasm initializes internal allocators, tile source logic, render state.
8. On each frame, Wasm writes a command stream into memory.
9. Host interprets the command stream and issues GPU API calls.
10. Input/events/resources are fed back to Wasm through ABI exports/imports.

---

## 5. Terminology

- **Spec**: the declarative map input accepted by the compiler.
- **Compiled module**: the output Wasm binary.
- **Host ABI**: the set of functions, memory, and conventions shared between browser JS and Wasm.
- **IR**: internal representation used by the compiler.
- **Bucket**: packed per-layer renderable geometry or draw data for a tile.
- **Command stream**: a compact binary render instruction buffer emitted by Wasm.
- **Schema**: typed description of tile layers and feature properties.
- **Dynamic class**: the evaluation frequency bucket of a value or expression.

---

## 6. Input specification

### 6.1 Top-level input model

The compiler input shall contain the following top-level sections:

```json
{
  "version": 1,
  "style": { ... },
  "sources": { ... },
  "schema": { ... },
  "assets": { ... },
  "interaction": { ... },
  "target": { ... },
  "constraints": { ... },
  "build": { ... }
}
```

### 6.2 `style`

The style section defines:
- layers,
- source bindings,
- source-layer references,
- filters,
- paint properties,
- layout properties,
- zoom-dependent behavior,
- optional feature-state references,
- optional transitions.

The compiler may accept a MapLibre-style JSON-compatible subset or a canonical internal schema that can be derived from it.

### 6.3 `sources`

The sources section defines runtime data inputs. For v1, supported source type is:
- vector tile source.

Each source shall define:
- id,
- tiling scheme,
- URL template or fetch descriptor,
- min/max zoom,
- extent,
- compression format,
- optional tile envelope metadata.

### 6.4 `schema`

The schema section is mandatory for compilation-time specialization.

For each vector tile source layer, it shall define:
- feature geometry kind,
- known property names,
- property types,
- value domains where known,
- encoding strategy,
- stable field ids,
- optional enum dictionaries,
- optional default values,
- optional nullability.

Example:

```json
{
  "roads": {
    "geometry": "line",
    "properties": {
      "class": { "type": "enum", "values": ["motorway", "primary", "secondary", "street"] },
      "bridge": { "type": "bool", "default": false },
      "tunnel": { "type": "bool", "default": false },
      "layer": { "type": "i8", "default": 0 }
    }
  }
}
```

### 6.5 `assets`

The assets section describes:
- sprite sheets,
- icons,
- image atlases,
- glyph source descriptors,
- any static textures,
- optional embedded shader templates.

### 6.6 `interaction`

This section declares the dynamic interaction model allowed at runtime.

Examples:
- camera pan/zoom/rotate,
- hover queries,
- click selection,
- feature-state mutation,
- viewport resize,
- time-varying animation parameters.

Anything not declared here may be rejected or compiled out.

### 6.7 `target`

Defines the compilation target.

For v1:

```json
{
  "platform": "browser",
  "graphics": "webgl2",
  "wasm": {
    "memory_pages_initial": 256,
    "memory_pages_max": 1024,
    "shared": false
  }
}
```

### 6.8 `constraints`

Defines specialization assumptions.

Examples:
- `allow_runtime_restyle: false`
- `allow_feature_state: false`
- `allow_symbols: false`
- `schema_locked: true`
- `fixed_tile_extent: 4096`

### 6.9 `build`

Compilation controls:
- optimization level,
- debug info,
- deterministic build mode,
- instrumentation,
- target CPU-independent settings,
- feature toggles.

---

## 7. Support matrix

### 7.1 v1 supported features

- browser target
- WebGL2 backend
- vector tile sources
- layer types: background, fill, line, circle
- camera pan/zoom/rotate
- tile culling
- source schema specialization
- generated shader programs
- shared-memory command stream submission

### 7.2 v1 excluded features

- general symbol placement
- terrain
- globe projection
- heatmap
- hillshade
- raster DEM
- runtime restyling
- arbitrary expression evaluator shipped to client
- generic source plugins

### 7.3 v2 candidates

- symbol layers with constrained model
- fill-extrusion
- WebGPU backend
- multi-source compositing
- off-main-thread worker host
- limited feature-state support

---

## 8. Compiler architecture

### 8.1 Implementation language split

- **Lua**: orchestration, parsing, validation, IR construction, analysis, specialization, code generation control.
- **Terra**: typed runtime kernels, data-layout-sensitive codegen, low-level math, Wasm-targeted compiled functions, helper intrinsics.

### 8.2 Compilation pipeline

1. Parse input spec.
2. Normalize style defaults.
3. Validate sources and schemas.
4. Build canonical style tree.
5. Lower expressions into typed expression IR.
6. Build source-schema IR.
7. Build render graph IR.
8. Perform dependency classification and constness analysis.
9. Partial-evaluate expressions and prune dead branches.
10. Generate specialized layer evaluators.
11. Generate bucket builders and attribute layouts.
12. Generate shader IR and backend shaders.
13. Generate Wasm runtime code.
14. Emit manifests, tables, and static data segments.
15. Link and assemble final Wasm.
16. Emit diagnostics and compile report.

### 8.3 Determinism requirements

Given identical:
- input spec,
- compiler version,
- backend version,
- target configuration,

binary output shall be deterministic modulo explicitly versioned debug sections.

---

## 9. Intermediate representations

### 9.1 IR layers

The compiler shall use the following IR stages:

1. **Canonical Spec IR**
2. **Typed Expression IR**
3. **Schema IR**
4. **Layer Plan IR**
5. **Render Graph IR**
6. **Shader IR**
7. **Runtime IR**
8. **Command ABI IR**

### 9.2 Canonical Spec IR

Normalizes:
- explicit defaults,
- resolved source references,
- resolved layer order,
- flattened inheritance,
- canonical units,
- canonical property naming.

Example node:

```text
Layer {
  id: LayerId,
  kind: Line,
  source: SourceId,
  source_layer: SourceLayerId,
  minzoom: u8,
  maxzoom: u8,
  filter: ExprId,
  paint: PaintBlock,
  layout: LayoutBlock
}
```

### 9.3 Typed Expression IR

Each expression node shall record:
- result type,
- dependency class,
- purity,
- constantness,
- source property dependencies,
- feature-state dependency,
- zoom dependency,
- evaluation cost estimate.

Core node kinds:
- literal,
- get-property,
- has-property,
- feature-state,
- zoom,
- arithmetic,
- logical,
- compare,
- match,
- case,
- interpolate,
- let/bind,
- clamp,
- convert,
- color constructor,
- vector constructor.

### 9.4 Dependency classes

Each value or expression shall be classified into one of:

- `CONST_GLOBAL`
- `CONST_STYLE`
- `PER_FRAME`
- `PER_SOURCE`
- `PER_TILE`
- `PER_FEATURE`
- `PER_INTERACTION`

This classification drives specialization.

### 9.5 Schema IR

Schema IR shall represent:
- source layers,
- geometry kinds,
- property slots,
- packed types,
- enum dictionaries,
- field offsets,
- nullability and default semantics.

### 9.6 Layer Plan IR

Layer Plan IR shall capture, per layer:
- source binding,
- filter evaluator,
- sort behavior,
- bucket kind,
- vertex layout,
- uniform layout,
- state block,
- draw policy,
- associated shader program family.

### 9.7 Render Graph IR

Represents ordered passes and state transitions.

For v1 it may be a linear ordered pass list, but it shall support future extension to a richer graph.

### 9.8 Shader IR

Shader IR shall be backend-neutral and typed.

It shall represent:
- stage (vertex/fragment),
- inputs/outputs,
- uniforms,
- varyings,
- constants,
- arithmetic expressions,
- texture accesses,
- control flow,
- helper functions,
- precision class.

### 9.9 Runtime IR

Represents generated Wasm-side structures and procedures:
- map state,
- tile cache state,
- allocators,
- command encoder,
- event handlers,
- frame scheduler,
- upload staging memory,
- resource registries.

---

## 10. Expression semantics and specialization

### 10.1 Lowering rules

All style expressions shall be lowered into Typed Expression IR before any backend generation.

Example:

```json
["match", ["get", "class"], "motorway", 4, "primary", 2, 1]
```

becomes:

```text
MatchExpr {
  input: GetProperty(slot=CLASS_SLOT),
  arms: [
    EnumValue(MOTORWAY) -> Literal(4),
    EnumValue(PRIMARY) -> Literal(2)
  ],
  default: Literal(1),
  type: f32,
  dep: PER_FEATURE
}
```

### 10.2 Specialization rules

The compiler shall:
- constant-fold all pure constant subexpressions,
- hoist `PER_FRAME` expressions out of per-feature loops,
- hoist `PER_TILE` expressions into tile-precompute sections,
- reduce `match` on enums into dense switch tables when possible,
- specialize property access to fixed slot loads,
- remove branches proven unreachable under schema/domain constraints,
- fuse interpolations and scalar conversions where safe.

### 10.3 Unsupported dynamic constructs

If an expression requires unsupported runtime behavior under the active constraints, compilation shall fail with a precise diagnostic.

Examples:
- feature-state when disabled,
- string-to-color conversion at runtime,
- unsupported geometry-dependent operators.

### 10.4 Precision model

The compiler shall define explicit precision semantics for:
- integer arithmetic,
- floating point math,
- color normalization,
- interpolation,
- comparison behavior.

All backends shall preserve these semantics within declared tolerance bounds.

---

## 11. Source and tile model

### 11.1 Tile addressing

Tiles shall be identified by:
- source id,
- z,
- x,
- y,
- optional wrap,
- optional variant key.

### 11.2 Tile lifecycle

States:
- `UNREQUESTED`
- `REQUESTING`
- `READY_RAW`
- `DECODING`
- `READY_BUCKETED`
- `FAILED`
- `EVICTED`

### 11.3 Tile data pipeline

1. Wasm requests tile by logical tile id.
2. Host performs fetch and returns bytes.
3. Wasm decodes bytes.
4. Wasm maps properties through schema.
5. Wasm evaluates filters.
6. Wasm builds layer buckets.
7. Wasm stores ready-to-render tile data.

### 11.4 Decoding strategy

For v1, decoding shall target the selected vector tile format supported by the compiler.

The compiler may generate specialized decoders that:
- decode only referenced source layers,
- decode only referenced properties,
- map enums directly to compact ids,
- skip irrelevant geometry kinds,
- skip unreferenced feature metadata.

### 11.5 Geometry representation

Internally, geometry shall be represented in tile-local coordinates with explicit extent metadata.

Layer-specific bucket builders shall transform these coordinates into packed vertex/index buffers or command-friendly primitives.

---

## 12. Layer kinds

### 12.1 Background

- no source dependency,
- compiled into clear or fullscreen pass state,
- fully frame-dependent only.

### 12.2 Fill

- polygon geometry,
- solid color in v1,
- optional opacity,
- optional outline in later versions.

### 12.3 Line

- line string geometry,
- specialized width/color evaluators,
- joins/caps according to selected support subset,
- optional dash support later.

### 12.4 Circle

- point geometry,
- radius/color/opacity,
- optional stroke later.

### 12.5 Future layer kinds

- symbol,
- raster,
- fill-extrusion,
- hillshade,
- heatmap.

These shall have distinct bucket and shader strategies.

---

## 13. Bucket generation

### 13.1 Purpose

A bucket is the per-tile, per-layer prepared render data produced after filtering and evaluation.

### 13.2 Bucket kinds

- `FillBucket`
- `LineBucket`
- `CircleBucket`

### 13.3 Bucket contents

A bucket shall contain:
- tile id,
- layer id,
- vertex buffer range,
- index buffer range,
- per-bucket uniforms,
- bounding box,
- sort key,
- resource references,
- dirty flags,
- dynamic parameter masks.

### 13.4 Build phases

1. Iterate decoded features.
2. Evaluate filter.
3. Evaluate per-feature attributes.
4. Emit packed vertices.
5. Emit indices.
6. Compute bucket bounds.
7. Finalize resource references.

### 13.5 Attribute packing

Attribute layouts shall be generated per layer family.

Example line vertex:

```text
struct LineVertex {
  i16 x;
  i16 y;
  i16 extrude_x;
  i16 extrude_y;
  u16 distance;
  u16 attr0;
}
```

The exact fields are compiler-generated based on required shader inputs.

---

## 14. Render planning

### 14.1 Pass structure

For v1, render passes are a stable linear sequence:

1. background pass,
2. opaque/alpha-sorted fill passes as needed,
3. line passes,
4. circle passes.

### 14.2 State blocks

Each draw family shall have an immutable state block describing:
- blend enable/mode,
- depth/stencil settings,
- cull mode,
- program id,
- vertex layout id,
- texture bindings,
- uniform layout id.

### 14.3 Draw ordering

Ordering shall be determined by:
- style layer order,
- tile wrap order,
- optional bucket sort keys,
- selected blending policy.

### 14.4 Culling

At minimum:
- viewport culling,
- tile visibility,
- bucket bounds rejection.

Future versions may add finer per-feature culling.

---

## 15. Shader generation

### 15.1 General model

The compiler shall emit only the shader variants required by the compiled style.

No generic runtime shader flag system shall be shipped in the generated client unless explicitly enabled.

### 15.2 Shader inputs

Generated shaders may depend on:
- packed vertex attributes,
- per-draw uniforms,
- per-frame uniforms,
- texture samplers,
- constants embedded directly in shader code.

### 15.3 Shader specialization opportunities

The compiler shall embed constants directly into shader code where legal for:
- fixed colors,
- fixed opacities,
- disabled branches,
- fixed transforms,
- known attribute decode scales,
- known enum-driven cases.

### 15.4 Shader interface generation

The compiler shall generate:
- vertex input layout,
- uniform blocks or manual uniform binding metadata,
- varying declarations,
- program manifest,
- reflection metadata used by the host interpreter.

### 15.5 Shader cache key

Each emitted shader program family shall have a stable cache key derived from:
- compiler version,
- shader backend version,
- layer family,
- specialization hash,
- target graphics backend.

---

## 16. Wasm runtime architecture

### 16.1 Module responsibilities

The generated module owns:
- map state,
- tile cache,
- allocators,
- command encoder,
- frame state,
- interaction state,
- source request queue,
- render plan state,
- diagnostics ring buffer.

### 16.2 Core runtime subsystems

- Memory manager
- Tile manager
- Decoder subsystem
- Bucket builder subsystem
- Camera subsystem
- Visibility subsystem
- Command encoder
- Resource registry
- Event subsystem
- Diagnostics subsystem

### 16.3 Threading model

v1 shall assume single-threaded execution on the browser main thread.

Future versions may support Web Worker or shared-memory threading if the host environment allows it.

### 16.4 Memory ownership

All persistent map data shall reside in Wasm linear memory unless explicitly managed by the host via opaque handles.

### 16.5 Allocator strategy

Recommended allocator partitioning:
- static data region,
- long-lived heap,
- frame arena,
- tile decode arena,
- command stream arena,
- upload staging arena.

Frame arenas shall reset each frame. Tile decode arenas shall reset on decode completion.

---

## 17. Browser host ABI

### 17.1 ABI design goals

- explicit,
- small,
- stable,
- low-call-count,
- offset/length based,
- resource-handle based.

### 17.2 Memory contract

The browser host shall provide or accept a `WebAssembly.Memory` object.

Shared CPU-side data exchange uses:
- pointer offsets into memory,
- byte lengths,
- agreed struct layouts,
- little-endian encoding.

### 17.3 Imported functions

Recommended minimum host imports:

```text
host.now_ms() -> f64
host.log(level: i32, ptr: i32, len: i32)
host.request_frame()
host.canvas_size(ptr_out: i32)
host.submit_commands(ptr: i32, len: i32)
host.fetch_start(req_id: i32, url_ptr: i32, url_len: i32, kind: i32)
host.resource_release(kind: i32, handle: i32)
```

Optional imports:

```text
host.read_device_pixel_ratio() -> f32
host.performance_mark(tag_ptr: i32, tag_len: i32)
host.image_decode(req_id: i32, ptr: i32, len: i32)
```

### 17.4 Exported functions

Required Wasm exports:

```text
init() -> i32
frame() -> i32
resize(width: i32, height: i32, dpr_q16: i32) -> i32
pointer_move(x_q16: i32, y_q16: i32, buttons: i32, mods: i32) -> i32
pointer_down(x_q16: i32, y_q16: i32, buttons: i32, mods: i32) -> i32
pointer_up(x_q16: i32, y_q16: i32, buttons: i32, mods: i32) -> i32
wheel(dx_q16: i32, dy_q16: i32, mods: i32) -> i32
key_event(code: i32, down: i32, mods: i32) -> i32
resource_loaded(req_id: i32, status: i32, ptr: i32, len: i32) -> i32
resource_failed(req_id: i32, status: i32) -> i32
```

Optional exports:

```text
set_time_param(name_id: i32, value_q16: i32) -> i32
query_feature(x_q16: i32, y_q16: i32, out_ptr: i32, out_len: i32) -> i32
get_stats(ptr_out: i32) -> i32
```

### 17.5 Error codes

All ABI functions shall return integer status codes.

Minimum codes:
- `0`: OK
- `1`: RETRY_LATER
- `2`: INVALID_ARGUMENT
- `3`: OUT_OF_MEMORY
- `4`: UNSUPPORTED
- `5`: INTERNAL_ERROR

---

## 18. Shared memory layout

### 18.1 General rules

- little-endian
- naturally aligned where practical
- explicit versioned structs
- no raw pointers shared with JS except integer offsets into memory

### 18.2 Memory regions

Recommended fixed-header layout:

```text
+---------------------------+
| Module Header             |
+---------------------------+
| Global State              |
+---------------------------+
| Tile Cache                |
+---------------------------+
| Long-lived Heap           |
+---------------------------+
| Frame Arena               |
+---------------------------+
| Command Stream Arena      |
+---------------------------+
| Upload Staging Arena      |
+---------------------------+
| Diagnostics Ring Buffer   |
+---------------------------+
```

### 18.3 Module header

```text
struct ModuleHeader {
  u32 magic;
  u16 abi_version_major;
  u16 abi_version_minor;
  u32 feature_flags;
  u32 offsets_table_ptr;
  u32 reserved[4];
}
```

### 18.4 Common struct conventions

- all structs versioned if externally visible,
- array data represented by `{ptr, len}` pairs,
- strings as UTF-8 bytes,
- optional values via sentinel or explicit flag.

---

## 19. Command stream format

### 19.1 Motivation

The command stream minimizes Wasm↔JS call overhead by batching all rendering work into one memory buffer submission per frame or per pass.

### 19.2 Encoding model

A command stream is a byte sequence of commands:

```text
[opcode:u16][size:u16][payload...]
```

Commands shall be 4-byte aligned.

### 19.3 Frame structure

A frame command buffer begins with:

```text
FrameHeader {
  u32 magic;
  u16 version_major;
  u16 version_minor;
  u32 frame_id;
  u32 command_count;
  u32 flags;
}
```

### 19.4 Core opcodes

Minimum v1 opcodes:
- `BEGIN_FRAME`
- `END_FRAME`
- `CLEAR`
- `USE_PROGRAM`
- `BIND_VERTEX_BUFFER`
- `BIND_INDEX_BUFFER`
- `SET_VIEWPORT`
- `SET_BLEND_STATE`
- `SET_UNIFORM_BLOCK`
- `DRAW_INDEXED`
- `DRAW_ARRAYS`
- `UPLOAD_BUFFER`
- `CREATE_BUFFER`
- `DESTROY_BUFFER`
- `CREATE_PROGRAM`
- `DESTROY_PROGRAM`

### 19.5 Example command payloads

```text
struct CmdUseProgram {
  u32 program_id;
}

struct CmdBindVertexBuffer {
  u32 buffer_id;
  u32 offset;
  u16 layout_id;
  u16 slot;
}

struct CmdDrawIndexed {
  u32 mode;
  u32 count;
  u32 index_type;
  u32 index_offset;
  i32 base_vertex;
}
```

### 19.6 Resource handles

All host-side GPU objects shall be referenced by integer handles generated by the Wasm module and resolved by the host resource table.

### 19.7 Validation

The host interpreter shall validate:
- command buffer version,
- bounds,
- handle existence,
- layout consistency,
- payload size.

Invalid command streams may be rejected with diagnostic reporting.

---

## 20. Resource model

### 20.1 Resource kinds

- GPU buffer
- GPU program
- texture
- image atlas
- tile byte payload
- decoded tile blob

### 20.2 Resource ownership

- Wasm owns logical resource lifetimes.
- Host owns browser-side object realization.
- Resource handles remain stable until destroyed.

### 20.3 Creation strategy

Two models are supported:

1. **Eager**: create resources during initialization.
2. **Lazy**: emit creation commands upon first use.

v1 may use eager program creation and lazy buffer creation.

---

## 21. Camera and transforms

### 21.1 Camera state

The Wasm module owns:
- center coordinates,
- zoom,
- bearing,
- pitch,
- viewport size,
- device pixel ratio,
- projection matrices,
- inverse matrices if needed.

### 21.2 Coordinate spaces

The system shall define explicit conversions among:
- world coordinates,
- tile coordinates,
- layer-local coordinates,
- clip space,
- screen space.

### 21.3 Numeric representation

Fixed-point may be used for ABI-facing event coordinates. Internal math may use 32-bit or 64-bit floating point as selected by backend policy.

---

## 22. Event and interaction model

### 22.1 Event types

- resize
- pointer move
- pointer down/up
- wheel
- key input
- visibility changes in future

### 22.2 Interaction state

The module may maintain:
- drag state,
- inertial camera state,
- hover target,
- selection target,
- user-defined interaction variables declared in spec.

### 22.3 Interaction compilation

If the input spec declares interaction rules, they shall be lowered into runtime handlers inside Wasm, not interpreted by JS.

---

## 23. Networking and resource fetch

### 23.1 General model

The host performs browser fetches. Wasm owns request intent and request ids.

### 23.2 Request flow

1. Wasm enqueues request.
2. Wasm calls `host.fetch_start`.
3. Host performs fetch.
4. Host copies response bytes into shared memory.
5. Host calls `resource_loaded(req_id, status, ptr, len)`.
6. Wasm consumes bytes and transitions resource state.

### 23.3 URL generation

URL template expansion should occur in Wasm if the source descriptor is compiled into the module.

### 23.4 Caching

Browser HTTP caching is allowed. The Wasm module may additionally maintain logical tile cache state.

---

## 24. Error handling and diagnostics

### 24.1 Compile-time diagnostics

Compiler errors shall include:
- code,
- severity,
- message,
- spec path,
- layer/source context,
- suggested fix where possible.

### 24.2 Runtime diagnostics

The module shall maintain a diagnostics ring buffer in memory for:
- last error,
- resource failures,
- OOM conditions,
- unsupported host capabilities,
- invalid command submission states.

### 24.3 Host diagnostics

The host may log:
- command stream validation failures,
- WebGL errors,
- missing resources,
- shader compilation failures.

---

## 25. Security model

### 25.1 Trust boundaries

- Compiler input spec is untrusted unless validated.
- Network resources are untrusted.
- Browser host is trusted by the application but not by the module beyond ABI contract.

### 25.2 Compiler hardening

The compiler service shall:
- validate JSON sizes and nesting,
- bound memory use,
- reject unsupported constructs explicitly,
- avoid code generation from unchecked arbitrary strings.

### 25.3 Runtime hardening

The host interpreter shall:
- validate command buffers,
- check offsets/lengths against memory bounds,
- bound resource sizes,
- reject invalid handle reuse.

---

## 26. Performance requirements

### 26.1 Primary performance targets

- zero style interpretation in client runtime,
- one or few JS↔Wasm calls per frame,
- no JS object construction in hot render path,
- no redundant CPU-side copies between JS and Wasm memory,
- stable frame time under tile churn.

### 26.2 Compile-time optimization priorities

1. eliminate dead layers/properties,
2. specialize property access,
3. hoist expressions by dependency class,
4. reduce shader variants to actual usage,
5. minimize command count,
6. minimize buffer uploads.

### 26.3 Telemetry

Optional runtime stats:
- frame time,
- visible tiles,
- decoded tiles,
- bucket counts,
- command count,
- bytes uploaded,
- memory usage by arena.

---

## 27. Debuggability

### 27.1 Debug build mode

Debug builds may emit:
- named layer tables,
- source maps from compiled evaluator ids to spec paths,
- shader text dumps,
- command stream dumps,
- IR snapshots.

### 27.2 Inspection tools

Recommended compiler outputs in debug mode:
- canonical spec JSON,
- expression IR dump,
- specialization report,
- render graph dump,
- shader manifest,
- ABI manifest.

---

## 28. Compiler output package

### 28.1 Minimum output

Required:
- `map.wasm`

Optional:
- `map.manifest.json`
- `compile-report.json`
- `debug/` dumps

### 28.2 Manifest fields

```json
{
  "abi_version": "1.0",
  "graphics_backend": "webgl2",
  "features": ["fill", "line", "circle"],
  "memory": {
    "initial_pages": 256,
    "maximum_pages": 1024
  },
  "shader_programs": 6,
  "spec_hash": "...",
  "build_hash": "..."
}
```

---

## 29. Versioning

### 29.1 Version dimensions

- compiler version,
- spec schema version,
- host ABI version,
- command stream version,
- shader backend version.

### 29.2 Compatibility policy

- Patch versions must remain backward-compatible within the same major/minor ABI.
- Minor versions may add optional commands/imports/exports.
- Major versions may break binary compatibility.

---

## 30. Example lifecycle

### 30.1 Compile time

1. Input spec describes road, water, and city-point layers.
2. Schema states `roads.class` is a fixed enum.
3. Compiler lowers `match(get("class"))` into enum switch.
4. Compiler emits line width logic as per-feature evaluator.
5. Compiler embeds water fill color as shader literal.
6. Compiler emits three program families and bucket builders.
7. Final output is one `.wasm` module.

### 30.2 Runtime

1. Browser host loads `.wasm` and creates canvas.
2. Wasm initializes camera and requests initial tiles.
3. Host fetches tile bytes and returns them into memory.
4. Wasm decodes and buckets visible tiles.
5. Wasm emits a frame command stream.
6. Host interprets commands and submits WebGL draws.
7. User zooms; host forwards wheel event.
8. Wasm updates camera and emits new command stream.

---

## 31. Reference host behavior

### 31.1 Initialization sequence

1. Create canvas.
2. Acquire WebGL2 context.
3. Create `WebAssembly.Memory`.
4. Instantiate module with imports.
5. Call `init()`.
6. Read canvas size and DPR.
7. Call `resize(...)`.
8. Call `frame()`.
9. On each animation frame, call `frame()` only when module has requested one or host policy requires continuous draw.

### 31.2 Command submission loop

When `host.submit_commands(ptr, len)` is called:
1. Validate pointer and length.
2. Read frame header.
3. Iterate commands.
4. Map handles to browser resources.
5. Submit WebGL calls.
6. Optionally record timing.

---

## 32. Failure modes

### 32.1 Compile-time failure examples

- unsupported layer kind,
- expression depends on disallowed feature-state,
- schema missing required property,
- target backend lacks required capability,
- style contains unsupported dynamic mutation.

### 32.2 Runtime failure examples

- tile fetch failure,
- WebGL program link failure,
- out-of-memory in Wasm heap,
- malformed command stream,
- resource handle mismatch.

The system shall degrade predictably and surface diagnostics.

---

## 33. Conformance requirements

A conforming compiler implementation shall:
- accept valid input spec according to schema,
- perform semantic validation,
- produce a Wasm module implementing the declared host ABI,
- preserve declared style semantics within supported feature subset,
- emit deterministic output under deterministic mode.

A conforming host implementation shall:
- provide required imports,
- create the requested graphics context,
- interpret the command stream according to versioned spec,
- enforce memory and handle validation,
- forward required events and resource responses.

---

## 34. MVP definition

### 34.1 MVP scope

- browser + WebGL2
- one vector tile source
- known schema
- layer kinds: background/fill/line/circle
- no symbols
- no feature-state
- no runtime restyle
- command-buffer host ABI
- static shader generation
- deterministic build artifact

### 34.2 MVP success criteria

The MVP is successful if:
- the same input spec always produces the same Wasm,
- the Wasm renders the map correctly in browser,
- the browser host contains no generic style engine,
- no client-side style JSON interpretation occurs,
- JS↔Wasm render-path interaction is limited to a small fixed ABI,
- CPU-side data exchange occurs through shared memory and offset/length descriptors.

---

## 35. Future extensions

### 35.1 Symbol support

Add a dedicated symbol subsystem with:
- glyph atlas management,
- shaping,
- collision,
- constrained placement rules,
- optional partially generic runtime for labels.

### 35.2 WebGPU backend

Replace the WebGL2 command interpreter with a WebGPU submission backend and extend Shader IR to pipeline descriptions and bind groups.

### 35.3 Multi-threading

Move tile decoding and bucket generation to worker threads when browser capabilities permit.

### 35.4 Dynamic style parameters

Allow a restricted set of runtime parameters declared at compile time and lowered to stable ABI slots.

---

## 36. Recommended implementation order

### Phase 1
- canonical spec parser
- schema parser
- typed expression IR
- fill/line/circle support
- WebGL2 host shim
- basic command stream

### Phase 2
- vector tile decoder specialization
- bucket builders
- shader generator
- deterministic build pipeline
- debug reports

### Phase 3
- interaction compilation
- tile cache optimization
- instrumentation
- resource lifetime improvements

### Phase 4
- constrained symbol subsystem
- optional worker execution
- WebGPU investigation

---

## 37. Summary

This system is an ahead-of-time map compiler for the browser. It treats the map style and source schema as a static program, specializes it at build time, and emits a Wasm renderer that performs all map logic client-side with only a minimal JavaScript host boundary.

The defining characteristics are:
- no generic map engine in the browser client,
- no client-side style interpretation,
- a small stable host ABI,
- shared-memory CPU-side data exchange,
- command-buffer-based rendering submission,
- specialization of expressions, schemas, buckets, and shaders.

This specification is intended to be sufficient for implementation of a first conforming compiler and browser host.

