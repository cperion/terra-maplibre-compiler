#!/bin/bash
# ABI validation script

# Validates ABI conformance between compiler and host
set -e

echo "Validating ABI conformance..."
node ../../scripts/validate-abi.js
