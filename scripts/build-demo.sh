
#!/bin/bash
set -e

# Directories
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO_DIR="$ROOT_DIR/examples/demo"

echo "Building Demo..."

# 1. Compile map
echo "Compiling map-spec.json..."
cd "$ROOT_DIR/compiler"
# Using terra if available, otherwise assuming lua for the mock pipeline
if command -v terra &> /dev/null; then
    terra main.lua --input "$DEMO_DIR/map-spec.json" --output "$DEMO_DIR/map.wasm"
else
    lua main.lua --input "$DEMO_DIR/map-spec.json" --output "$DEMO_DIR/map.wasm"
fi

echo "Build complete."
echo "To run the demo:"
echo "  cd $ROOT_DIR"
echo "  npx http-server -c-1 ."
echo "  # Then open http://localhost:8080/examples/demo/"

# Check for terra availability
if command -v terra &> /dev/null; then
    echo "Using terra to build map.wasm..."
    # Execute the wasm_module.t file with terra to generate map.wasm
    # We navigate to compiler directory to run it
    cd "$ROOT_DIR/compiler"
    terra terra/wasm_module.t
    
    # Move result to demo dir
    if [ -f "map.wasm" ]; then
        mv map.wasm "$DEMO_DIR/map.wasm"
        echo "map.wasm generated successfully."
    else
        echo "Error: terra failed to generate map.wasm"
        exit 1
    fi
else
    echo "Warning: 'terra' command not found."
    if [ -f "$DEMO_DIR/map.wasm" ]; then
        echo "Using existing map.wasm in $DEMO_DIR."
    else
        echo "Error: No terra compiler and no pre-built map.wasm found."
        echo "Please install Terra or place a valid map.wasm in examples/demo/."
        exit 1
    fi
fi
