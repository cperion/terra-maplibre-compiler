# Host Tests

This directory contains tests for the browser host runtime.

## Test Categories

- **Unit Tests**: Test individual host components
- **Integration Tests**: Test host + Wasm interaction
- **ABI Tests**: Validate ABI conformance
- **Command Stream Tests**: Test command interpreter

## Running Tests

```bash
../../scripts/test-host.sh
```

## Test Organization

Tests should be organized by component:
- `loader/` - Wasm loading and instantiation
- `command-interpreter/` - Command stream execution
- `resource-tables/` - GPU resource management
- `event-bridge/` - Browser event forwarding
- `abi/` - ABI contract validation
