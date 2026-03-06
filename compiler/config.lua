-- Compiler configuration
-- Defines global constants, versioning, and default settings for the compiler.

local M = {}

-- Versioning
M.COMPILER_VERSION = "0.0.1-dev"
M.SPEC_VERSION = "1.0.0"
M.ABI_VERSION = "0.1.0"

-- Feature Flags
-- Controls which map features are supported by the generated Wasm.
M.features = {
    allow_symbols = false,         -- Symbol layers (text/icons)
    allow_runtime_restyle = false, -- Changing paint properties at runtime
    allow_feature_state = false    -- Per-feature state (hover/select)
}

-- Optimization Levels
M.OPT_DEBUG = 0  -- No optimization, maximum debug info
M.OPT_SIZE = 1   -- Optimize for binary size
M.OPT_SPEED = 2  -- Optimize for execution speed

-- Memory Configuration
-- Wasm linear memory settings (1 page = 64KB)
M.memory = {
    DEFAULT_MEMORY_PAGES_INITIAL = 256, -- 16 MB
    DEFAULT_MEMORY_PAGES_MAX = 1024     -- 64 MB
}

-- Tile Configuration
M.tile = {
    DEFAULT_TILE_EXTENT = 4096 -- Vector tile coordinate extent
}

-- Validation Settings
M.validation = {
    validate_schema = true, -- Validate input spec against JSON schema
    strict_mode = true      -- Fail on unknown properties
}

-- Build Configuration
M.build = {
    deterministic = true,   -- Ensure reproducible builds
    debug_info = false,     -- Include DWARF debug info
    instrumentation = false -- Inject performance counters
}

return M
