
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
