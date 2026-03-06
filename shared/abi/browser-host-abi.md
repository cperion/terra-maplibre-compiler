# Browser Host ABI Specification

**Version:** 0.1.0  
**Last Updated:** 2026-03-06  
**Status:** Draft

## Purpose

This document defines the contract between the browser host (JavaScript) and the generated WebAssembly module. The host provides a minimal, stable API that the module uses to interact with the browser environment.

## Design Principles

1. **Explicit**: All interfaces are versioned and documented
2. **Minimal**: Smallest possible API surface area
3. **Stable**: Breaking changes require major version bumps
4. **Low-call-count**: Batch operations via command streams
5. **Offset-based**: Data exchange via shared memory pointers

## Memory Contract

### Shared Memory

The browser host shall provide or accept a `WebAssembly.Memory` object.

**Data exchange conventions:**
- All CPU-side data uses shared linear memory
- Pointers passed as integer byte offsets
- Lengths passed as integer byte counts
- Little-endian encoding
- 4-byte minimum alignment
- Versioned structs for external visibility

### Memory Regions

```
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

## Host Imports

The Wasm module may import the following functions from the host:

### Required Imports

```c
// Timing
double now_ms();

// Logging
void log(int32_t level, int32_t ptr, int32_t len);

// Frame scheduling
void request_frame();

// Canvas information
void canvas_size(int32_t ptr_out);

// Command submission
void submit_commands(int32_t ptr, int32_t len);

// Network fetch
void fetch_start(int32_t req_id, int32_t url_ptr, int32_t url_len, int32_t kind);

// Resource cleanup
void resource_release(int32_t kind, int32_t handle);
```

### Optional Imports

```c
// Device pixel ratio
float read_device_pixel_ratio();

// Performance marking
void performance_mark(int32_t tag_ptr, int32_t tag_len);

// Image decoding
void image_decode(int32_t req_id, int32_t ptr, int32_t len);
```

## Wasm Exports

The Wasm module must export the following functions:

### Required Exports

```c
// Initialization
int32_t init();

// Frame execution
int32_t frame();

// Viewport resize
int32_t resize(int32_t width, int32_t height, int32_t dpr_q16);

// Pointer events
int32_t pointer_move(int32_t x_q16, int32_t y_q16, int32_t buttons, int32_t mods);
int32_t pointer_down(int32_t x_q16, int32_t y_q16, int32_t buttons, int32_t mods);
int32_t pointer_up(int32_t x_q16, int32_t y_q16, int32_t buttons, int32_t mods);

// Scroll wheel
int32_t wheel(int32_t dx_q16, int32_t dy_q16, int32_t mods);

// Keyboard
int32_t key_event(int32_t code, int32_t down, int32_t mods);

// Resource callbacks
int32_t resource_loaded(int32_t req_id, int32_t status, int32_t ptr, int32_t len);
int32_t resource_failed(int32_t req_id, int32_t status);
```

### Optional Exports

```c
// Time-varying parameters
int32_t set_time_param(int32_t name_id, int32_t value_q16);

// Feature queries
int32_t query_feature(int32_t x_q16, int32_t y_q16, int32_t out_ptr, int32_t out_len);

// Statistics
int32_t get_stats(int32_t ptr_out);
```

## Status Codes

All ABI functions return integer status codes:

| Code | Name               | Meaning                                    |
|------|--------------------|--------------------------------------------|
| 0    | OK                 | Success                                    |
| 1    | RETRY_LATER        | Operation would block, retry later         |
| 2    | INVALID_ARGUMENT   | Invalid parameter provided                 |
| 3    | OUT_OF_MEMORY      | Memory allocation failed                  |
| 4    | UNSUPPORTED        | Operation not supported                   |
| 5    | INTERNAL_ERROR     | Internal module error                     |

## Calling Conventions

### Integer Encoding

- Coordinates use Q16.16 fixed-point format (16 integer bits, 16 fractional bits)
- This provides sub-pixel precision without floating point

### String Encoding

- Strings passed as UTF-8 byte sequences
- Pointer to string bytes + length in bytes
- Host and module must agree on lifetime/ownership

### Struct Layout

- All structs versioned with `version_major` and `version_minor` fields
- 4-byte aligned minimum
- Little-endian byte order
- No padding unless explicitly documented
- Arrays represented as `{ptr, len}` pairs

## Version Negotiation

### Module Header

The module must include a header at a known offset (typically 0):

```c
struct ModuleHeader {
  uint32_t magic;           // 0x54455252 ('TERR')
  uint16_t abi_version_major;
  uint16_t abi_version_minor;
  uint32_t feature_flags;
  uint32_t offsets_table_ptr;
  uint32_t reserved[4];
};
```

### Compatibility Check

The host must:
1. Read the module header from memory
2. Check `magic` field equals `0x54455252`
3. Verify `abi_version_major` matches expected major version
4. Verify `abi_version_minor` >= expected minimum minor version
5. Proceed with instantiation if compatible

## Resource Handles

All GPU resources are referenced by integer handles:

| Kind       | Handle Type         | Notes                          |
|------------|---------------------|--------------------------------|
| Program    | `program_id`        | Shader program                 |
| Buffer     | `buffer_id`         | Vertex/Index/Uniform buffer    |
| Texture    | `texture_id`        | Texture object                 |
| Request    | `req_id`            | Network request identifier     |

**Ownership:**
- Wasm owns logical resource lifetimes
- Host owns browser-side object realization
- Handles remain stable until destroyed

## Error Handling

### Host-side Validation

The host must validate:
- Command stream version compatibility
- Pointer and length bounds
- Handle existence and type
- Layout consistency
- Payload sizes

### Module-side Diagnostics

The module maintains a diagnostics ring buffer for:
- Last error information
- Resource failures
- OOM conditions
- Unsupported host capabilities
- Invalid states

## Threading Model

**Version 0.1 assumes single-threaded execution on the browser main thread.**

Future versions may support:
- Web Worker execution
- Shared memory threading
- Off-main-thread tile decoding

## ABI Evolution Policy

### Version Compatibility

- **Patch versions** (0.1.x): Bug fixes only, fully compatible
- **Minor versions** (0.x.0): May add optional imports/exports, backward compatible
- **Major versions** (x.0.0): Breaking changes, requires recompilation

### Deprecation

- Features may be deprecated for one major version cycle
- Deprecation warnings logged via `host.log()`
- Removal requires major version bump

## Implementation Requirements

### Host Implementation Must

- Provide all required imports
- Validate all inputs before use
- Implement command stream interpreter
- Forward browser events
- Manage GPU resource lifecycle

### Module Implementation Must

- Export all required exports
- Return valid status codes
- Maintain valid memory state
- Emit valid command streams
- Handle all host callbacks

## Testing Conformance

A conforming host must pass:
- Module instantiation test
- Command stream execution test
- Event forwarding test
- Resource lifecycle test

A conforming module must pass:
- Export signature test
- Status code test
- Command stream validity test
- Memory layout test
