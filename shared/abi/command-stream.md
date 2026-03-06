# Command Stream Specification

**Version:** 0.1.0

## Overview

The command stream protocol minimizes the overhead of Wasm↔JavaScript calls by batching GPU commands into shared memory buffers. Instead of calling individual WebGL functions for every operation, the Wasm module writes a linear sequence of commands into a "Frame Arena," which the host reads and executes in a tight loop.

## Frame Structure

Every frame submission begins with a header block describing the batch.

```c
struct FrameHeader {
    uint32_t magic;           // 0x46524D45 ('FRME')
    uint16_t version_major;   // 0x0000
    uint16_t version_minor;   // 0x0001
    uint32_t frame_id;        // Monotonically increasing ID
    uint32_t command_count;   // Number of commands in this batch
    uint32_t flags;           // Frame-specific flags
    uint32_t reserved;        // Padding to 24 bytes
};
```

## Command Format

Each command consists of a 4-byte header followed by a variable-length payload. Payloads are always padded to 4-byte boundaries.

```c
struct CommandHeader {
    uint16_t opcode;          // Command identifier
    uint16_t size;            // Total size of command (header + payload + padding)
};
```

## Opcode Table (v0.1.0)

| Opcode | Name                 | Description                     |
|--------|----------------------|---------------------------------|
| 0x0001 | BEGIN_FRAME          | Start of frame rendering        |
| 0x0002 | END_FRAME            | End of frame rendering          |
| 0x0003 | CLEAR                | Clear framebuffer               |
| 0x0004 | USE_PROGRAM          | Bind shader program             |
| 0x0005 | CREATE_BUFFER        | Allocate GPU buffer             |
| 0x0006 | UPLOAD_BUFFER        | Upload data to GPU buffer       |
| 0x0007 | BIND_VERTEX_BUFFER   | Bind vertex buffer to slot      |
| 0x0008 | BIND_INDEX_BUFFER    | Bind index buffer               |
| 0x0009 | SET_VIEWPORT         | Set render viewport             |
| 0x000A | SET_BLEND_STATE      | Configure blending              |
| 0x000B | SET_UNIFORM_BLOCK    | Update uniform data             |
| 0x000C | DRAW_INDEXED         | Draw indexed geometry           |
| 0x000D | DRAW_ARRAYS          | Draw non-indexed geometry       |
| 0x000E | DESTROY_BUFFER       | Free GPU buffer                 |
| 0x000F | DESTROY_PROGRAM      | Free shader program             |

## Command Payloads

### Control Commands

**BEGIN_FRAME (0x0001)**
No payload.

**END_FRAME (0x0002)**
No payload.

### State Commands

**CLEAR (0x0003)**
```c
struct CmdClear {
    uint8_t r, g, b, a;       // Clear color (0-255)
    float depth;              // Clear depth (0.0 - 1.0)
    uint8_t stencil;          // Clear stencil value
    uint8_t flags;            // Bit 0: Color, Bit 1: Depth, Bit 2: Stencil
    uint16_t padding;         // Align to 4 bytes
};
```

**USE_PROGRAM (0x0004)**
```c
struct CmdUseProgram {
    uint32_t program_id;      // Handle of program to bind
};
```

**SET_VIEWPORT (0x0009)**
```c
struct CmdSetViewport {
    int32_t x, y;             // Origin
    int32_t width, height;    // Dimensions
    float min_depth;          // Usually 0.0
    float max_depth;          // Usually 1.0
};
```

**SET_BLEND_STATE (0x000A)**
```c
struct CmdSetBlendState {
    uint8_t enabled;          // 0 or 1
    uint8_t src_rgb;          // GL enum
    uint8_t dst_rgb;          // GL enum
    uint8_t src_alpha;        // GL enum
    uint8_t dst_alpha;        // GL enum
    uint8_t equation_rgb;     // GL enum
    uint8_t equation_alpha;   // GL enum
    uint8_t padding;
};
```

### Buffer Management

**CREATE_BUFFER (0x0005)**
```c
struct CmdCreateBuffer {
    uint32_t buffer_id;       // Handle to assign
    uint32_t size;            // Size in bytes
    uint32_t usage;           // GL_STATIC_DRAW, GL_DYNAMIC_DRAW, etc.
};
```

**UPLOAD_BUFFER (0x0006)**
```c
struct CmdUploadBuffer {
    uint32_t buffer_id;       // Handle
    uint32_t offset;          // Offset into buffer
    uint32_t data_ptr;        // Pointer to data in shared memory
    uint32_t length;          // Length of data
};
```

**DESTROY_BUFFER (0x000E)**
```c
struct CmdDestroyBuffer {
    uint32_t buffer_id;       // Handle to free
};
```

### Drawing Commands

**BIND_VERTEX_BUFFER (0x0007)**
```c
struct CmdBindVertexBuffer {
    uint32_t slot;            // Attribute slot
    uint32_t buffer_id;       // Buffer handle
    uint32_t stride;          // Vertex stride
    uint32_t offset;          // Offset in buffer
};
```

**BIND_INDEX_BUFFER (0x0008)**
```c
struct CmdBindIndexBuffer {
    uint32_t buffer_id;       // Buffer handle
    uint32_t type;            // GL_UNSIGNED_SHORT or GL_UNSIGNED_INT
};
```

**DRAW_INDEXED (0x000C)**
```c
struct CmdDrawIndexed {
    uint32_t mode;            // GL_TRIANGLES, etc.
    uint32_t count;           // Index count
    uint32_t type;            // GL_UNSIGNED_SHORT, etc.
    uint32_t offset;          // Byte offset in index buffer
};
```

**DRAW_ARRAYS (0x000D)**
```c
struct CmdDrawArrays {
    uint32_t mode;            // GL_TRIANGLES, etc.
    uint32_t first;           // Starting vertex
    uint32_t count;           // Vertex count
};
```

## Validation Rules

1. **Alignment**: All commands must start on a 4-byte boundary.
2. **Bounds Checking**: `ptr + size` must not exceed the frame arena size.
3. **Handle Validation**: Host must verify that `program_id` and `buffer_id` refer to valid, existing resources.
4. **Pointer Validation**: `data_ptr` in upload commands must point to valid shared memory regions.

## Resource Handle Semantics

- **IDs** are generated by the Wasm module.
- **Buffers**: ID is an index into a sparse array on the host side.
- **Programs**: ID maps to a compiled WebGLProgram.
- **Lifecycle**: Resources exist until explicitly destroyed via `DESTROY_*` commands.
