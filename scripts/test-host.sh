#!/bin/bash
# Host test runner  
# Runs all host tests
set -e

echo "Running host tests..."
# Assuming tests are run via npm in the host directory
cd ../host && npm test
