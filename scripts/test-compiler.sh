#!/usr/bin/env bash
# Compiler test runner
# Runs all compiler tests
set -euo pipefail

# Compute root directory from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DIR="$ROOT_DIR/compiler/tests"

echo "Running compiler tests..."

# Validate test directory exists
if [ ! -d "$TEST_DIR" ]; then
	echo "Error: Test directory not found: $TEST_DIR"
	exit 1
fi

# Determine which Lua interpreter to use
LUA_INTERPRETER=""
if command -v terra &>/dev/null; then
	LUA_INTERPRETER="terra"
	echo "Using Terra interpreter"
elif command -v lua &>/dev/null; then
	LUA_INTERPRETER="lua"
	echo "Using Lua interpreter"
else
	echo "Error: No Lua interpreter found. Please install 'terra' or 'lua'."
	exit 1
fi

# Find and run all test files in deterministic order
test_files=($(find "$TEST_DIR" -name "*.test.lua" -type f | sort))

if [ ${#test_files[@]} -eq 0 ]; then
	echo "Warning: No test files found in $TEST_DIR"
	exit 0
fi

echo "Found ${#test_files[@]} test file(s)"
echo ""

failed=0
passed=0

for test_file in "${test_files[@]}"; do
	test_name=$(basename "$test_file")
	echo "Running: $test_name"

	if "$LUA_INTERPRETER" "$test_file"; then
		echo "  PASS"
		((passed += 1))
	else
		echo "  FAIL"
		((failed += 1))
	fi
	echo ""
done

echo "========================================"
echo "Test Results: $passed passed, $failed failed"
echo "========================================"

if [ $failed -gt 0 ]; then
	exit 1
fi
