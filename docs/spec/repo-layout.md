# Repository Layout Guide
**Version:** 1.0.0  
**Last Updated:** 2026-03-06

## Directory Structure

```
terra-maplibre-compiler/
├── compiler/                  # Terra/Lua compiler service
│   ├── lua/               # Lua orchestration code
│   ├── terra/              # Terra code generation
│   └── tests/               # Compiler tests
│
├── host/                     # Browser host runtime
│   ├── js/                # JavaScript host implementation
│   └── tests/             # Host tests
│
├── shared/                   # Cross-cutting concerns
│   ├── abi/               # ABI specifications
│   ├── schemas/          # JSON schemas
│   └── fixtures/          # Test data
│       ├── specs/          # Sample map specs
│       ├── schemas/       # Sample schemas
│       └── commands/      # Command stream fixtures
│
├── examples/                # Working examples
│   └── minimal/           # Clear-only example
│
├── docs/                     # Documentation
│   └── spec/               # Technical specs
│
└── scripts/                 # Build utilities
```

## Key Files

### Compiler Service
- `compiler/VERSION` - Compiler version
- `compiler/lua/*.lua` - Lua source files
- `compiler/terra/*.t` - Terra source files

- `compiler/tests/*.lua` - Test files

### Host Runtime
- `host/VERSION` - Host version
- `host/js/index.js` - Main entry point
- `host/js/*.js` - JavaScript modules
- `host/tests/*.js` - Test files

### Shared Resources
- `shared/abi/browser-host-abi.md` - ABI specification
- `shared/abi/browser-host-abi.json` - ABI schema
- `shared/schemas/map-compile-spec.schema.json` - Input spec schema
- `shared/fixtures/specs/*.json` - Sample specifications
- `shared/fixtures/commands/*.bin` - Binary command fixtures

### Examples
- `examples/minimal/spec.json` - Minimal map spec
- `examples/minimal/README.md` - Example documentation

### Build Scripts
- `Makefile` - Build orchestration
- `scripts/test-compiler.sh` - Run compiler tests
- `scripts/test-host.sh` - Run host tests
- `scripts/validate-abi.sh` - Validate ABI conformance

