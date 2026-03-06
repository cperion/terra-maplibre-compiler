# Included as context AI!
#!/bin/bash
# Compiler test runner
# Runs all compiler tests
set -e

echo "Running compiler tests..."

# Find and run all Lua test files in the compiler/tests directory
if [ -d "../compiler/tests" ]; then
    find ../compiler/tests -name "*.lua" -exec terra {} \;
else
    echo "Error: compiler/tests directory not found"
    exit 1
fi


# Rewrite this script to be robust like a root-aware runner: use `#!/usr/bin/env bash` and `set -euo pipefail`; compute `ROOT_DIR` from `BASH_SOURCE`; set `TEST_DIR="$ROOT_DIR/compiler/tests"`; validate that directory exists; iterate all `*.lua` files under it (deterministic order) and run each using `terra` if available, otherwise `lua`; print clear progress lines and fail with a helpful message if no interpreter exists. AI!