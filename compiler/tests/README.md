# Compiler Tests

This directory contains tests for the Terra/Lua compiler service.

## Test Categories

- **Unit Tests**: Test individual compiler components
- **Integration Tests**: Test end-to-end compilation pipelines
- **Fixture Tests**: Validate compiler against test fixtures

## Running Tests

```bash
../../scripts/test-compiler.sh
```

## Test Organization

Tests should be organized by compiler phase:
- `parser/` - Spec parsing and canonicalization
- `schema/` - Schema IR building
- `expression/` - Expression IR lowering and specialization
- `layer-plan/` - Layer plan generation
- `codegen/` - Code generation
