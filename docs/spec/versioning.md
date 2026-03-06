# Version Compatibility Model

**Version:** 1.0.0  
**Last Updated:** 2026-03-06

## Overview

The Terra AOT Map Compiler uses semantic versioning across multiple dimensions:

### Version Dimensions

1. **Compiler Version** (`compiler/VERSION`)
   - Format: `major.minior.patch`
   - Example: `0.0.1-dev`
   - Incremented for each release
   - Tracks: `0.1.0`, `1.1.0`, `1.2.0`, etc.

2. **Spec Schema Version** (`shared/schemas/spec-version.json`)
   - Format: `major.minor.patch`
   - Example: `1.0.0`
   - Incremented when breaking changes to spec schema
   - Current: `1.0.0`

3. **Host ABI Version** (`shared/abi/version.json`)
   - Format: `major.minor.patch`
   - Example: `0.1.0`
   - Incremented when breaking changes to ABI contract
   - Requires recompilation of generated Wasm modules

4. **Command Stream Version** (defined in command stream spec)
   - Format: `major.minor.patch`
   - Incremented when new opcodes added
   - Requires careful negotiation

5. **Shader Backend Version** (internal)
   - Tracks WebGL2 vs WebGPU support

### Compatibility Rules

#### Patch Versions (x.y.z)
- **Definition**: Bug fixes, documentation updates
- **Compatibility**: **Fully backward compatible**
- **ABI Impact**: None
- **Example**: `0.1.0` → `0.1.1`

**Implementation:**
- Fix bugs without changing interfaces
- Update documentation
- Improve performance
- **Testing**: Must pass existing test suite
- **Deployment**: Safe to drop-in replacement

#### Minor Versions (x.y.0)
- **Definition**: New features, optional additions
- **Compatibility**: **Backward compatible**
- **ABI Impact**: May add new optional imports/exports to command opcodes
- **Example**: `0.1.0` → `0.2.0`

**Implementation:**
- Add new shader features
- Add new command opcodes (optional)
- Extend command stream with new payload types
- Add optional host imports
- **Testing**: All existing tests must pass
- New tests for new features
- **Deployment**: Can incrementally roll out; must rollback if critical issues

#### Major Versions (x.0.0)
- **Definition**: Breaking changes
- **Compatibility**: **Not backward compatible**
- **ABI Impact**: Breaking changes require recompilation of generated Wasm modules
- **Example**: `0.1.0` → `1.0.0`

**Implementation:**
- Restructure internal IR
- Change command stream protocol
- Remove deprecated features
- **Testing**: May need significant test updates
- **Deployment**: Requires coordinated rollout; not recommended for production

### Version Compatibility Matrix

| Compiler Version | Spec Version | Host ABI Version | Command Stream | Compatible? |
|-------------------|--------------|------------------|----------------|-------------|
| 0.0.1             | 1.0.0        | 0.1.0            | 0.1.0          | ✓           |
| 0.0.1             | 1.1.0        | 0.1.0            | 0.1.0          | ✓           |
| 0.0.1             | 1.0.0        | 1.0.0            | 0.1.0          | ✗ (recompile) |
| 1.0.0             | 1.0.0        | 0.1.0            | 0.1.0          | ✗ (recompile) |

### Deprecation Policy

When features are deprecated:
1. **Warning Period**: Deprecation warnings logged for one major version cycle
2. **Removal**: Features removed in next major version
3. **Migration Path**: Clear migration path documented in release notes

### Current Versions

| Component          | Version | Status      |
|--------------------|---------|------------|
| Compiler           | 0.0.1    | Development |
| Spec Schema         | 1.0.0   | Stable      |
| Host ABI            | 0.1.0   | Experimental |
| Command Stream     | 0.1.0   | Experimental |

### Version Bumping Process

1. **Identify Change**: Determine if change is patch, minor, or major
2. **Update Files**: Modify all relevant version files
3. **Update Docs**: Update version compatibility documentation
4. **Test Compatibility**: Verify compatibility across version matrix
5. **Update Changelog**: Document changes in CHANGELOG.md

### Testing Version Compatibility

#### ABI Conformance Tests
- Host must module version checks
- Export signature validation
- Import resolution
- Status code handling

#### Specification Tests
- Schema version validation
- Default value insertion
- Reference resolution
- Type checking

#### Integration Tests
- End-to-end compilation with version combinations
- Module instantiation with different ABI versions
- Cross-version compatibility verification

### Future Version Planning

#### Potential v0.2.0 Changes
- Add additional command opcodes
- Extend event types
- Add optional host capabilities
- Improve memory layout

#### Potential v1.0.0 Changes
- Stabilize experimental features
- Add symbol layer support
- Optimize command stream encoding
- Consider WebGPU backend

### Version Checklist for Changes

When making changes, verify:
- [ ] All version files updated
- [ ] Compatibility matrix updated
- [ ] Tests added for new features
- [ ] Documentation updated
- [ ] Migration path documented (if major)
- [ ] Deprecation warnings added (if removing features)
