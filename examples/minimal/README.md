# Minimal Example

This is the minimal working example that proves the core architecture: a map spec that compiles to a Wasm module that clears the canvas via the command stream ABI.

## Purpose

This example validates:

- Host ABI contract
- Memory layout
- Command stream protocol
- Wasm instantiation
- Command execution
- Browser integration

## Build

```bash
cd examples/minimal
make build
```

## Run

Open `index.html` in a browser to see the cleared canvas.

## What it demonstrates

- The compiler can parse a trivial spec
- The compiler emits a valid Wasm module
- The browser host can load the module
- The module can initialize and emit a clear command
- The host can execute the command stream
- No style interpretation happens in the browser
