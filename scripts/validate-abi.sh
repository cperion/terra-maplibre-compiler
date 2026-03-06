# Included as context AI!
#!/bin/bash
# ABI validation script

# Validates ABI conformance between compiler and host
set -e

echo "Validating ABI conformance..."
node ../../scripts/validate-abi.js

# Rewrite this script so it no longer references a missing JS file. Keep it as a shell wrapper that computes `ROOT_DIR` and then runs an inline Node validation (`node --input-type=module`) to: (1) parse `shared/abi/version.json` and `shared/abi/browser-host-abi.json`, (2) verify ABI major/minor/patch match between both files, (3) ensure required top-level arrays `imports`, `exports`, and `status_codes` exist and are non-empty, and (4) print a success line with the version string. Exit non-zero with a clear error message on failure. AI!