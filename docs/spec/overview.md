# System Overview

**Version:** 1.0.0  
**Last Updated:** 2026-03-06

## Architecture

The Terra AOT Map Compiler consists of three main components:

### 1. Compiler Service (Terra/Lua)
Parses input map specifications and lowers them to specialized Wasm renderer
- Input: JSON map spec + schema
- Output: `map.wasm` + metadata

### 2. Browser Host (JavaScript)
Thin runtime that loads and instantiates the module, provides canvas + WebGL2 context, and executes command streams
- Input: `map.wasm` binary
- Output: Rendered map

### 3. Generated Wasm Module
Specialized renderer containing all map logic
- No external style engine
- Direct GPU command execution
- Optimized for the specific map

## Key Design Principles

1. **Compile, don't interpret** - All style semantics resolved at compile time
2. **Specialize aggressively** - Only code needed for the target spec
3. **Thin host boundary** - Minimal, explicit ABI
4. **Shared memory** - CPU-side data via offsets/lengths
5. **Command streams** - Batch GPU commands via memory buffers

## Implementation Status

- **Phase 1**: Repository scaffolding (current)
- **Phase 2**: ABI contracts
- **Phase 3**: Browser host shell
- **Phase 4**: Compiler frontend
- **Phase 5**: Code generation

- **Phase 6**: Integration testing

## See Also

- [Technical Specification](./starting-docs/terra_wasm_map_compiler_technical_spec.md)
- [AI Agent Tasklist](./starting-docs/ai_agent_tasklist_terra_wasm_map_compiler.md)
- [IR Documentation](./starting-docs/intermediate_representations_terra_wasm_map_compiler.md)
