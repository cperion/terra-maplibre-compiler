# AI Agent Task List: Terra AOT Map Compiler to Browser Wasm

## Purpose

This document is an implementation-oriented task list for an AI coding agent. It translates the technical specification into a concrete, staged build plan. The goal is to let a capable coding agent implement the system step by step with minimal ambiguity.

This is not a product brief. It is a sequencing and execution document.

---

## Project outcome

Build a system with two parts:

1. a **Terra/Lua compiler service** that accepts a map spec and emits a specialized browser Wasm module,
2. a **thin browser host runtime** that fetches that Wasm, creates a canvas and WebGL2 context, shares memory with the module, and executes a command stream emitted by the module.

The browser runtime must not interpret map styles at runtime.

---

## Ground rules for the agent

1. Do not build a generic browser map engine.
2. Do not add runtime style interpretation to the client.
3. Do not start with symbol rendering.
4. Do not start with WebGPU.
5. Do not optimize for unlimited flexibility in v0.
6. Prefer stable boundaries over cleverness.
7. Keep every interface versioned.
8. Every phase must end in a runnable artifact.
9. Every binary layout must have tests.
10. Every major step must produce written developer notes in the repo.

---

## Recommended repo layout

```text
repo/
  compiler/
    lua/
    terra/
    tests/
  host/
    js/
    tests/
  shared/
    schemas/
    abi/
    fixtures/
  examples/
    minimal/
    roads/
    fills/
  docs/
    spec/
    reports/
  scripts/
```

---

## Execution strategy

Implement from the outside in:

1. lock the ABI,
2. create a fake Wasm-compatible host harness,
3. create a tiny command stream interpreter,
4. create a minimal generated module shape,
5. then fill in compiler lowering, bucket building, and rendering.

This reduces architecture churn.

---

# Phase 0: Project bootstrap

## Goal

Create the initial repository, tooling skeleton, versioning policy, and minimum runnable scaffolding.

## Tasks

### 0.1 Create repo structure
- Create the recommended directory layout.
- Add README files to `compiler/`, `host/`, `shared/`, `examples/`, and `docs/`.
- Add a top-level architecture overview.

### 0.2 Define version files
- Create `shared/abi/version.json`.
- Create `shared/schemas/spec-version.json`.
- Create compiler version constant.
- Create host runtime version constant.

### 0.3 Add build scripts
- Add scripts for:
  - running compiler tests,
  - running host tests,
  - building examples,
  - emitting debug reports.

### 0.4 Add fixtures
- Add one minimal style/spec fixture.
- Add one minimal vector tile schema fixture.
- Add one expected compiler output manifest fixture.

### 0.5 Write bootstrap docs
- Add `docs/spec/overview.md`.
- Add `docs/spec/versioning.md`.
- Add `docs/spec/repo-layout.md`.

## Deliverable

A clean repo with scripts, versioned folders, and placeholder fixtures.

## Acceptance criteria

- Repo can be cloned and bootstrapped by another agent.
- All directories exist.
- All version files exist.
- At least one script runs successfully.

---

# Phase 1: Lock the browser host ABI

## Goal

Define the exact boundary between browser host and generated Wasm before building compiler internals.

## Tasks

### 1.1 Create ABI markdown doc
Write `shared/abi/browser-host-abi.md` with:
- imported functions,
- exported functions,
- status codes,
- calling conventions,
- version negotiation,
- memory ownership rules.

### 1.2 Create machine-readable ABI schema
Write `shared/abi/browser-host-abi.json` containing:
- ABI version,
- import names and signatures,
- export names and signatures,
- error code enums,
- struct names.

### 1.3 Define status codes
Include:
- OK
- RETRY_LATER
- INVALID_ARGUMENT
- OUT_OF_MEMORY
- UNSUPPORTED
- INTERNAL_ERROR

### 1.4 Define event encoding
Specify exact argument types for:
- resize,
- pointer move,
- pointer down,
- pointer up,
- wheel,
- key event.

### 1.5 Define host capability query format
Specify a versioned struct for host capabilities:
- canvas size,
- device pixel ratio,
- graphics backend id,
- max texture size,
- optional feature flags.

### 1.6 Add ABI tests
Create tests that validate:
- import names are stable,
- export names are stable,
- ABI JSON parses,
- ABI versions are well-formed.

## Deliverable

A frozen v0 ABI spec and machine-readable ABI schema.

## Acceptance criteria

- ABI doc and JSON exist.
- Tests fail if signatures change unexpectedly.
- Another agent can implement host/runtime against the ABI without guessing.

---

# Phase 2: Define shared memory layout

## Goal

Create the memory contract used by both the browser host and Wasm module.

## Tasks

### 2.1 Write memory layout document
Create `shared/abi/memory-layout.md` defining:
- global header,
- fixed regions,
- dynamic arenas,
- alignment rules,
- little-endian assumption,
- `{ptr, len}` conventions.

### 2.2 Define binary structs
Create `shared/abi/memory-layout.json` with structs for:
- module header,
- host capability block,
- diagnostics ring header,
- command stream header,
- optional stats block.

### 2.3 Define offset policy
Specify which regions are:
- fixed offset,
- runtime allocated,
- frame-reset,
- tile-decode temporary,
- long-lived.

### 2.4 Add memory layout test vectors
Create byte-level test fixtures for:
- module header,
- command stream header,
- diagnostics record.

### 2.5 Add parsers/encoders
Implement small reference parsers in JS for binary struct validation.

## Deliverable

Versioned shared memory documentation, schema, and fixtures.

## Acceptance criteria

- Binary layouts are explicit.
- Test vectors round-trip.
- JS parser can validate fixture bytes.

---

# Phase 3: Define the command stream protocol

## Goal

Create the binary render command protocol that the Wasm module emits and the browser host executes.

## Tasks

### 3.1 Write command stream spec
Create `shared/abi/command-stream.md` describing:
- frame header,
- command header,
- opcode table,
- payload alignment,
- validation rules,
- resource handle semantics.

### 3.2 Create opcode enum
Define initial v0 opcodes:
- BEGIN_FRAME
- END_FRAME
- CLEAR
- USE_PROGRAM
- CREATE_BUFFER
- UPLOAD_BUFFER
- BIND_VERTEX_BUFFER
- BIND_INDEX_BUFFER
- SET_VIEWPORT
- SET_BLEND_STATE
- SET_UNIFORM_BLOCK
- DRAW_INDEXED
- DRAW_ARRAYS
- DESTROY_BUFFER
- DESTROY_PROGRAM

### 3.3 Define exact binary payloads
For each opcode define:
- struct fields,
- field sizes,
- field alignment,
- valid ranges,
- host validation checks.

### 3.4 Create command stream fixtures
Add fixture files for:
- empty frame,
- clear-only frame,
- one draw frame,
- invalid frame for negative testing.

### 3.5 Write host-side parser tests
Create parser tests for:
- valid command stream acceptance,
- invalid length rejection,
- unknown opcode rejection,
- misaligned payload rejection.

## Deliverable

Stable v0 command stream protocol plus fixtures and tests.

## Acceptance criteria

- Browser host can parse fixture streams.
- Invalid streams are rejected with useful errors.
- Another agent could write a command encoder from the spec alone.

---

# Phase 4: Implement thin browser host shell

## Goal

Create the smallest browser runtime that can instantiate Wasm, create a canvas, and interpret a command stream.

## Tasks

### 4.1 Create host module entrypoint
Build `host/js/index.js` that:
- accepts a canvas or selector,
- creates a WebGL2 context,
- instantiates Wasm,
- sets up imports,
- binds events,
- starts the frame loop.

### 4.2 Create resource tables
Implement host-side tables for:
- program handles,
- buffer handles,
- texture handles later,
- pending fetch handles.

### 4.3 Implement command interpreter
Implement a switch-based interpreter for the v0 command stream.

### 4.4 Add host logging hooks
Implement:
- info/warn/error logging,
- command validation logs,
- optional timing logs.

### 4.5 Add event forwarding
Wire browser events to Wasm exports:
- resize,
- pointer,
- wheel,
- keyboard.

### 4.6 Add requestAnimationFrame policy
Support:
- host-triggered frame loop,
- Wasm-requested redraw scheduling.

### 4.7 Add host tests
Use a browser-capable test setup to validate:
- module loads,
- imports exist,
- event forwarding paths work,
- command parser is invoked.

## Deliverable

A minimal browser host that can run a fake Wasm producer and execute simple command streams.

## Acceptance criteria

- Host can instantiate a test module.
- Host can execute a clear-only frame.
- Host can execute one triangle draw from a fixture command stream.

---

# Phase 5: Implement a fake generated module harness

## Goal

Before building the compiler, create a minimal manual Wasm producer shape so the host and ABI can be tested end to end.

## Tasks

### 5.1 Create a test producer module
Implement a temporary module or equivalent mock that:
- exports the required ABI functions,
- writes a fixed command stream into memory,
- requests frame submission.

### 5.2 Support clear-only output
Make the fake module emit:
- BEGIN_FRAME,
- CLEAR,
- END_FRAME.

### 5.3 Support one draw call output
Extend fake module to emit:
- CREATE_BUFFER,
- UPLOAD_BUFFER,
- USE_PROGRAM,
- DRAW_ARRAYS or DRAW_INDEXED.

### 5.4 Add ABI conformance tests
Validate:
- exported symbols,
- memory buffer layout,
- command submission behavior,
- host compatibility.

## Deliverable

A manually authored Wasm-compatible harness that proves the host ABI and command stream work.

## Acceptance criteria

- Browser shows a cleared canvas.
- Browser shows one simple draw.
- No map compiler exists yet, but the runtime path is proven.

---

# Phase 6: Define canonical input spec and schema format

## Goal

Lock the compiler inputs before implementing parsing and lowering.

## Tasks

### 6.1 Write input spec schema
Create `shared/schemas/map-compile-spec.schema.json` for:
- version,
- style,
- sources,
- schema,
- assets,
- interaction,
- target,
- constraints,
- build.

### 6.2 Write schema docs
Add markdown docs for each top-level section.

### 6.3 Define source schema format
Create `shared/schemas/vector-source-schema.schema.json` for:
- source layers,
- geometry kind,
- property definitions,
- enum dictionaries,
- defaults,
- nullability.

### 6.4 Add fixtures
Add minimal valid examples for:
- one fill layer,
- one line layer,
- one circle layer,
- one invalid spec.

### 6.5 Add schema validation tests
Validate all fixtures.

## Deliverable

Machine-readable compiler input schema and examples.

## Acceptance criteria

- Specs are validated before compilation.
- Invalid specs produce useful errors.
- Another agent can generate valid input files from the schema.

---

# Phase 7: Implement compiler frontend parser and canonicalizer

## Goal

Parse the input spec and lower it into a canonical internal representation.

## Tasks

### 7.1 Implement parser
Build Lua code that parses:
- style,
- sources,
- schema,
- target,
- constraints.

### 7.2 Canonicalize defaults
Resolve:
- default paint values,
- default layout values,
- source references,
- min/max zoom defaults,
- layer ordering.

### 7.3 Normalize identifiers
Create stable internal ids for:
- layers,
- sources,
- source layers,
- properties,
- assets.

### 7.4 Emit canonical spec dump
Add a debug output that writes canonical JSON.

### 7.5 Add frontend tests
Test:
- valid parsing,
- default insertion,
- stable ordering,
- invalid reference errors.

## Deliverable

A parser that emits canonical spec IR.

## Acceptance criteria

- Canonical output is deterministic.
- Defaults are explicit in the dump.
- Invalid input fails before later passes.

---

# Phase 8: Implement typed expression IR

## Goal

Lower style expressions into a typed, analyzable IR.

## Tasks

### 8.1 Define expression node types
Support initial nodes:
- literal,
- get-property,
- has-property,
- zoom,
- arithmetic,
- compare,
- logical,
- match,
- case,
- interpolate,
- convert.

### 8.2 Define type system
Support initial scalar types:
- bool,
- i32,
- f32,
- color,
- enum,
- string only where needed for parsing.

### 8.3 Implement expression parser
Lower style expressions into typed nodes.

### 8.4 Attach dependency classes
Classify each node as:
- CONST_GLOBAL,
- CONST_STYLE,
- PER_FRAME,
- PER_TILE,
- PER_FEATURE,
- PER_INTERACTION.

### 8.5 Add IR dump format
Write human-readable dumps for each expression tree.

### 8.6 Add tests
Cover:
- enum match lowering,
- zoom interpolate lowering,
- invalid type mismatches,
- dependency classification.

## Deliverable

Typed expression IR with parser, typing, and dependency tagging.

## Acceptance criteria

- All supported style expressions lower into IR.
- IR nodes have explicit types and dependency classes.
- Invalid expressions fail with precise diagnostics.

---

# Phase 9: Implement schema-aware property access lowering

## Goal

Use source schema to replace dynamic property lookups with stable slots and typed access.

## Tasks

### 9.1 Assign property slots
Generate stable integer slots for each referenced property.

### 9.2 Implement enum dictionaries
Convert declared enums into compact ids.

### 9.3 Lower property access nodes
Transform `get("class")` into slot-based access nodes.

### 9.4 Validate missing property references
Fail compilation if style references schema-unknown properties when schema lock is enabled.

### 9.5 Add tests
Validate:
- slot stability,
- enum lowering,
- schema mismatch errors,
- default value behavior.

## Deliverable

Schema-aware property access in IR.

## Acceptance criteria

- No runtime string property lookup is needed for supported features.
- Property loads are slot-based.
- Enum matches are dense and typed.

---

# Phase 10: Implement specialization and partial evaluation passes

## Goal

Erase as much runtime work as possible from the compiled module.

## Tasks

### 10.1 Implement constant folding
Fold all pure constant subtrees.

### 10.2 Implement dependency hoisting
Hoist:
- frame-only expressions,
- tile-only expressions,
- style constants.

### 10.3 Implement dead branch elimination
Remove branches made unreachable by:
- constants,
- schema constraints,
- disabled features.

### 10.4 Implement match lowering
Lower enum matches into:
- jump tables,
- compact switch tables,
- fixed arrays where beneficial.

### 10.5 Emit specialization report
Write debug output showing:
- original node count,
- folded node count,
- hoisted expressions,
- rejected dynamic constructs.

### 10.6 Add tests
Verify:
- constant-folded expressions,
- hoisted zoom expressions,
- reduced match logic,
- stable output.

## Deliverable

A specialization pass that materially reduces runtime IR complexity.

## Acceptance criteria

- Expression trees shrink on representative inputs.
- Compiler emits reports proving specialization occurred.
- Unsupported dynamic constructs fail early.

---

# Phase 11: Define layer plan IR

## Goal

Represent exactly how each compiled layer will be rendered.

## Tasks

### 11.1 Create layer plan structs
Each layer plan must include:
- layer id,
- kind,
- source binding,
- filter evaluator,
- bucket kind,
- attribute layout,
- uniform layout,
- state block,
- shader family id.

### 11.2 Implement layer-plan builder
Generate layer plans from canonical spec + specialized expressions.

### 11.3 Add validation
Reject plans that require unsupported backend features.

### 11.4 Add dumps and tests
Create readable layer-plan dumps and deterministic tests.

## Deliverable

A stable layer plan IR bridging frontend semantics to runtime generation.

## Acceptance criteria

- Every supported layer compiles into a layer plan.
- Layer plan contains no unresolved style references.

---

# Phase 12: Implement minimal vector tile decode pipeline

## Goal

Decode only the tile data needed for v0 rendering.

## Tasks

### 12.1 Choose concrete tile format support
Pick the exact vector tile encoding for v0 and document it.

### 12.2 Implement decode structures
Decode:
- feature geometry,
- referenced properties only,
- referenced source layers only.

### 12.3 Implement geometry-kind filtering
Skip geometry not relevant to compiled layers.

### 12.4 Implement schema projection
Project raw feature data into typed decoded records using slots and enums.

### 12.5 Add decode tests
Use small fixture tiles to test:
- lines,
- polygons,
- points,
- enum decoding,
- omitted property skipping.

## Deliverable

A selective decoder suitable for the supported layer subset.

## Acceptance criteria

- Decoder does not build generic feature objects.
- Unreferenced properties are skipped.
- Decoded records are directly usable by bucket builders.

---

# Phase 13: Implement bucket builders for fill, line, and circle

## Goal

Convert decoded tile features into packed renderable bucket data.

## Tasks

### 13.1 Define bucket structs
Create bucket layouts for:
- FillBucket,
- LineBucket,
- CircleBucket.

### 13.2 Define vertex formats
Create explicit packed vertex structs per layer family.

### 13.3 Implement filter evaluation
Use specialized filter evaluators during bucket construction.

### 13.4 Implement per-feature attribute evaluation
Evaluate remaining per-feature values and pack them into vertices or bucket metadata.

### 13.5 Compute bounds
Compute per-bucket bounding boxes for culling.

### 13.6 Add tests
Use fixture decoded data to validate:
- output vertex counts,
- index counts,
- attribute packing,
- bounds.

## Deliverable

Bucket builders that prepare render data for the supported layer kinds.

## Acceptance criteria

- Buckets are deterministic.
- Buckets contain packed data ready for draw submission.
- Buckets can be rendered by a simple shader path.

---

# Phase 14: Implement shader IR and WebGL2 shader generation

## Goal

Generate only the shaders needed by the compiled style.

## Tasks

### 14.1 Define shader IR
Represent:
- inputs,
- outputs,
- uniforms,
- varyings,
- expressions,
- helper functions,
- stage kind.

### 14.2 Implement family generators
Add shader generation for:
- fill,
- line,
- circle.

### 14.3 Add constant embedding
Embed fixed colors/opacities/branch eliminations into shaders when possible.

### 14.4 Emit reflection metadata
Generate metadata for:
- attribute layouts,
- uniform bindings,
- program names,
- program handles.

### 14.5 Add shader tests
Test:
- emitted GLSL validity,
- stable program key generation,
- expected uniform/interface layout.

## Deliverable

Shader generation pipeline for v0 layer families.

## Acceptance criteria

- Compiler emits valid GLSL for supported layers.
- Program count matches compiled style needs.
- Reflection metadata is sufficient for host submission.

---

# Phase 15: Implement Wasm runtime code generation skeleton

## Goal

Create the generated module structure that will own runtime state and emit command streams.

## Tasks

### 15.1 Define runtime state structs
Include:
- camera state,
- tile cache state,
- resource registry,
- command encoder state,
- frame stats,
- diagnostics ring.

### 15.2 Define allocator strategy
Implement:
- long-lived heap,
- frame arena,
- decode arena,
- command arena.

### 15.3 Implement export stubs
Generate the required ABI exports.

### 15.4 Implement command encoder
Add helper functions for writing aligned commands into command memory.

### 15.5 Add runtime initialization path
Initialize state from host capabilities and compiled constants.

### 15.6 Add runtime tests
Validate:
- arena reset,
- command encoding,
- export signatures,
- struct initialization.

## Deliverable

A generated runtime skeleton that can emit valid command streams.

## Acceptance criteria

- Generated module can initialize cleanly.
- Command encoder writes protocol-conformant bytes.
- Exported ABI is correct.

---

# Phase 16: Connect tile lifecycle and runtime fetching

## Goal

Make the runtime request tiles, receive bytes, decode them, and build buckets.

## Tasks

### 16.1 Implement tile ids and cache entries
Include:
- z/x/y,
- source id,
- state,
- resource pointers,
- last-used timestamp.

### 16.2 Implement visible tile selection
Compute visible tiles from camera state.

### 16.3 Implement request queue
Generate fetch requests for missing visible tiles.

### 16.4 Implement resource-loaded path
When host returns bytes:
- decode,
- build buckets,
- store ready tile data.

### 16.5 Implement eviction policy
Add a simple bounded cache with LRU-like eviction.

### 16.6 Add tests
Validate:
- visible set selection,
- request deduplication,
- state transitions,
- eviction behavior.

## Deliverable

A working tile lifecycle inside the generated runtime.

## Acceptance criteria

- Runtime requests visible tiles.
- Returned tiles are decoded and bucketed.
- Eviction does not corrupt rendering.

---

# Phase 17: Implement render planning and command emission

## Goal

Turn ready buckets into a per-frame command buffer the host can execute.

## Tasks

### 17.1 Implement pass ordering
Support ordered passes for:
- background,
- fill,
- line,
- circle.

### 17.2 Implement bucket culling
Use viewport and bucket bounds to skip invisible buckets.

### 17.3 Implement resource creation commands
Emit commands to create and upload buffers and programs as needed.

### 17.4 Implement draw emission
Emit the correct draw sequence for each visible bucket.

### 17.5 Implement per-frame clear and viewport commands
Emit frame boilerplate.

### 17.6 Add tests
Validate:
- command count,
- draw ordering,
- resource reuse,
- culling behavior.

## Deliverable

A full frame encoder for v0 rendering.

## Acceptance criteria

- Visible buckets produce valid command streams.
- Host renders expected results.
- Resource creation is not redundantly repeated every frame.

---

# Phase 18: Implement camera controls and interaction

## Goal

Support pan, zoom, and basic browser interaction with no JS-side map logic.

## Tasks

### 18.1 Implement camera model
Support:
- center,
- zoom,
- bearing,
- viewport,
- device pixel ratio.

### 18.2 Implement input handlers in Wasm
Handle:
- drag-pan,
- wheel zoom,
- resize.

### 18.3 Implement frame invalidation policy
Request redraw only when:
- camera changes,
- resources arrive,
- animations are active if enabled.

### 18.4 Add tests
Validate:
- stable pan behavior,
- zoom bounds,
- viewport update path,
- redraw scheduling.

## Deliverable

Usable map interaction controlled entirely by compiled Wasm.

## Acceptance criteria

- User can pan and zoom.
- Host remains thin and declarative.
- Interaction logic is not duplicated in JS.

---

# Phase 19: Add diagnostics, reports, and debug artifacts

## Goal

Make the compiler and runtime inspectable enough for agent-driven iteration.

## Tasks

### 19.1 Emit compiler reports
Add:
- canonical spec dump,
- expression IR dump,
- specialization report,
- layer plan dump,
- shader manifest,
- build manifest.

### 19.2 Implement diagnostics ring buffer
Store runtime warnings and errors in memory.

### 19.3 Add host-side diagnostic display hooks
Make it easy to print or inspect module diagnostics.

### 19.4 Add debug build mode
Enable extra symbols, assertions, and command dumps.

## Deliverable

A debuggable system with enough introspection for future agents.

## Acceptance criteria

- Failures are inspectable.
- Reports explain what the compiler generated.
- Runtime issues can be surfaced without browser devtools guesswork.

---

# Phase 20: Build end-to-end examples

## Goal

Prove the system with progressively more realistic examples.

## Tasks

### 20.1 Minimal clear example
A module that only clears the canvas.

### 20.2 Static geometry example
A module that draws static precompiled geometry.

### 20.3 One fill-layer tile example
A simple polygon source rendered from decoded tile data.

### 20.4 Roads example
One line layer with enum-based width/color logic.

### 20.5 Mixed layer example
Background + fill + line + circle.

### 20.6 Add visual regression tests
Capture browser images and compare them against baselines.

## Deliverable

A set of examples that prove progressive capability.

## Acceptance criteria

- Every example runs in browser.
- Regressions are visible.
- Each example corresponds to one milestone in the build plan.

---

# Phase 21: Stabilization and polish

## Goal

Make the v0 implementation stable enough for handoff or further extension.

## Tasks

### 21.1 Remove dead experimental branches
Delete unused paths and stale temporary code.

### 21.2 Freeze v0 ABI
Tag and document the final v0 ABI.

### 21.3 Freeze fixture set
Lock golden fixtures for:
- ABI,
- memory,
- command streams,
- canonical spec,
- shader outputs,
- visual baselines.

### 21.4 Add performance smoke tests
Measure:
- command emission time,
- tile decode time,
- bucket build time,
- frame render time.

### 21.5 Write handoff docs
Document:
- how to add a new layer type,
- how to add a new opcode,
- how to add a new expression node,
- how to debug compiler output.

## Deliverable

A stable v0 system with documentation and regression coverage.

## Acceptance criteria

- ABI is versioned and frozen.
- Golden tests pass.
- Examples work consistently.
- Another agent can continue development without rediscovering architecture.

---

# Priority order summary

If the agent must strictly prioritize, use this order:

1. ABI
2. Memory layout
3. Command stream
4. Browser host shell
5. Fake Wasm producer
6. Input schemas
7. Canonical parser
8. Expression IR
9. Schema-aware property lowering
10. Specialization passes
11. Layer plan IR
12. Tile decoder
13. Bucket builders
14. Shader generation
15. Wasm runtime skeleton
16. Tile lifecycle
17. Render command emission
18. Camera and interaction
19. Diagnostics
20. End-to-end examples
21. Stabilization

---

# Rules for autonomous agents working this task list

## When blocked

If blocked, do not redesign the architecture. First check whether the needed answer is already implied by:
- the technical spec,
- the ABI docs,
- the command stream docs,
- the current phase goal.

Only propose architecture changes if the blockage is fundamental.

## When adding files

Every new public interface file must include:
- version,
- purpose,
- owner subsystem,
- last-updated note.

## When changing binary layouts

Always:
- bump the relevant version,
- regenerate fixtures,
- update parser tests,
- update docs.

## When adding features

Never add:
- symbols,
- runtime style interpretation,
- generic plugin systems,
- broad client-side flexibility,

before v0 is complete.

---

# Definition of done for v0

v0 is done when all of the following are true:

- A valid compile spec can be parsed and canonicalized.
- Supported expressions lower into typed IR.
- Schema-aware lowering removes dynamic property name lookups.
- Specialization folds static logic.
- The compiler emits a browser-targeted Wasm module.
- The browser host can load that module and provide the stable ABI.
- The module can request tiles, decode them, build buckets, and emit render commands.
- The host can execute the command stream and render background, fill, line, and circle layers.
- The browser client contains no generic style interpreter.
- End-to-end examples and golden tests pass.

---

# Suggested first implementation milestone

The first milestone should be intentionally tiny:

**Compile a trivial spec into a Wasm module that clears a WebGL2 canvas through the command stream ABI.**

That milestone proves:
- host ABI,
- memory layout,
- command stream,
- Wasm instantiation,
- command execution,
- browser integration.

Do not skip this milestone.

---

# Suggested second implementation milestone

**Compile a trivial spec into a Wasm module that draws one static triangle or quad.**

That milestone proves:
- program creation,
- buffer upload,
- draw calls,
- resource handles,
- shader submission path.

---

# Suggested third implementation milestone

**Compile one fill layer from one vector tile schema into a runnable browser renderer.**

That milestone proves:
- frontend parsing,
- expression lowering,
- schema projection,
- tile decode,
- bucket building,
- real map rendering.

---

# Final instruction to the agent

Build the narrowest possible version that preserves the architecture. Do not chase feature completeness. The correct v0 is small, rigid, inspectable, and end-to-end functional.

