# Quick Start Guide

**Prerequisites:**
- Terra (>= 1.0.0)
- Lua (>= 5.3)
- Node.js (>= 16.0)
- Modern browser with WebGL2

## Repository Setup

```bash
# Clone the repository
git clone <repo-url>
cd terra-maplibre-compiler

# Install dependencies
make install
```

## Project Structure

```
terra-maplibre-compiler/
├── compiler/          # Terra/Lua compiler service
│   ├── lua/             # Lua orchestration
│   ├── terra/           # Terra code generation
│   └── tests/          # Compiler tests
├── host/              # Browser runtime
│   ├── js/              # JavaScript host
│   └── tests/          # Host tests
├── shared/            # Shared resources
│   ├── abi/             # ABI contracts
│   ├── schemas/       # JSON schemas
│   └── fixtures/       # Test data
├── examples/          # Example projects
│   └── minimal/       # Minimal example
├── docs/              # Documentation
│   └── spec/           # Specifications
└── scripts/           # Build utilities
```

## Running the Minimal Example

```bash
# Build the example
cd examples/minimal
make build

# Serve locally
python3 -m http.server localhost:8080

# Open in browser
open http://localhost:8080
```

## Running Tests

```bash
# Run compiler tests
make test-compiler

# Run host tests
make test-host

# Validate ABI
make validate-abi
```

## Building Examples

```bash
# Build all examples
make examples
```

## Development Workflow

1. **Write a spec** in `examples/` directory
2. **Create schema** in `shared/fixtures/schemas/`
3. **Build the example** using the compiler
4. **Test in browser** using the host
5. **Verify rendering output**

## Next Steps

1. Add more example specs
2. Implement tile decoding
3. Add bucket builders
4. Implement shader generation
5. Add camera controls
6. Add interaction handling

## Documentation

- [Technical Spec](docs/spec/overview.md)
- [Architecture Diagrams](docs/architecture.md)
- [API Reference](docs/api-reference.md)
- [Development Guide](docs/development-guide.md)
