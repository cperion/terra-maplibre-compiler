# Terra Map Compiler

A WebAssembly-based map renderer system that compiles declarative map specifications into specialized, single-purpose WebAssembly modules for zero runtime style interpretation.

    
## Purpose

    This repository implements the Terra AOT (Ahead-of-time) map compiler that transforms declarative map specifications into specialized WebAssembly renderer modules. that run in the browser with zero JavaScript dependencies beyond a thin host runtime.
    
## Philosophy
    
    - **Compile, don't interpret** - All map semantics are resolved at compile time
    - **Specialize aggressively** - Generated code is optimized for the target spec
    - **Zero client-side style engine** - No generic map library is shipped to the browser
    - **Schema-first** - Use schemas to optimize data access and rendering

## Architecture

```
┌─────────────────┐       ┌─────────────────┐
│   Input Spec     │──────>│   Compiler     │──────>│  Generated   │
│   (JSON)         │       │   (Terra/Lua)   │       │   Wasm Module  │
└─────────────────┘       └─────────────────┘
                           │                         │
                           ▼                         │
                    ┌─────────────────┐
                    │ Browser Host   │
                    │ (JS + WebGL2)│
                    └─────────────────┘
                                         │
                                  Events
                                   │
                    ┌──────────────────┐
                    │ Resource Fetch  │
                    └──────────────────┘
```
