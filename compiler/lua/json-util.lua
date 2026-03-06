-- FILE CONTEXT: New deterministic JSON writer utility for canonical dumps. AI!

-- Create a small module with `encode(value)` that serializes Lua tables to JSON deterministically: object keys sorted lexicographically; arrays emitted in index order; proper escaping for strings and support for numbers/booleans/null. This only needs to support current compiler data types. AI!