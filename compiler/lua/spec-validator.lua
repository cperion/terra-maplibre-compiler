-- FILE CONTEXT: New module that validates parsed input specs and returns structured errors without throwing by default. AI!

-- Create a validator module with API:
- `validate(spec) -> ok:boolean, errors:array`
- `assert_valid(spec) -> true or throws with joined human-readable message`
Each error should include at least a readable string message; include path-ish prefixes like `style.layers[2].source` where practical. AI!

-- Implement all minimum validation rules from context. Ensure duplicate layer IDs are caught. Ensure unknown source references are caught for non-background layers. AI!

-- Accept both source locations (`spec.style.sources` and `spec.sources`) for validation. When both exist, treat merged view as available sources, with `style.sources` taking precedence on conflicts. AI!