#!/bin/bash
# ABI validation script

# Validates ABI conformance between compiler and host
set -e

# Compute root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Validating ABI conformance..."

# Run inline Node.js validation
node --input-type=module - <<'EOF'
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const rootDir = process.env.ROOT_DIR;
const versionPath = join(rootDir, 'shared/abi/version.json');
const abiPath = join(rootDir, 'shared/abi/browser-host-abi.json');

try {
  // Parse both JSON files
  const versionData = JSON.parse(readFileSync(versionPath, 'utf8'));
  const abiData = JSON.parse(readFileSync(abiPath, 'utf8'));

  // Extract version numbers
  const vMajor = versionData.abi_version_major;
  const vMinor = versionData.abi_version_minor;
  const vPatch = versionData.abi_version_patch;
  
  const aMajor = abiData.abi_version.major;
  const aMinor = abiData.abi_version.minor;
  const aPatch = abiData.abi_version.patch;

  // Verify versions match
  if (vMajor !== aMajor || vMinor !== aMinor || vPatch !== aPatch) {
    console.error(`ERROR: ABI version mismatch!`);
    console.error(`  version.json: ${vMajor}.${vMinor}.${vPatch}`);
    console.error(`  browser-host-abi.json: ${aMajor}.${aMinor}.${aPatch}`);
    process.exit(1);
  }

  // Ensure required arrays exist and are non-empty
  if (!Array.isArray(abiData.imports) || abiData.imports.length === 0) {
    console.error('ERROR: "imports" array is missing or empty in browser-host-abi.json');
    process.exit(1);
  }

  if (!Array.isArray(abiData.exports) || abiData.exports.length === 0) {
    console.error('ERROR: "exports" array is missing or empty in browser-host-abi.json');
    process.exit(1);
  }

  if (!Array.isArray(abiData.status_codes) || abiData.status_codes.length === 0) {
    console.error('ERROR: "status_codes" array is missing or empty in browser-host-abi.json');
    process.exit(1);
  }

  // Success
  console.log(`✓ ABI validation passed: v${vMajor}.${vMinor}.${vPatch}`);
  console.log(`  - ${abiData.imports.length} imports`);
  console.log(`  - ${abiData.exports.length} exports`);
  console.log(`  - ${abiData.status_codes.length} status codes`);

} catch (err) {
  console.error(`ERROR: ABI validation failed: ${err.message}`);
  process.exit(1);
}
EOF

export ROOT_DIR
