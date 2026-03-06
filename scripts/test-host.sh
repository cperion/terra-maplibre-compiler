#!/usr/bin/env bash
# Host test runner
# Runs host unit tests and optional integration test.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running host tests..."
node "$ROOT_DIR/host/tests/resource-tables.test.js"
node "$ROOT_DIR/host/tests/command-interpreter.test.js"
node "$ROOT_DIR/host/tests/integration.test.js"
