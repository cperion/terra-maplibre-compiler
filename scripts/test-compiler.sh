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

