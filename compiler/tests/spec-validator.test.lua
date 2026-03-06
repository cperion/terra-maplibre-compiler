-- FILE CONTEXT: New validator unit tests for core invalid/valid scenarios. AI!

-- Create table-driven tests for: valid minimal background spec, duplicate layer ids, unsupported layer type, missing source for non-background layer, unknown source reference, invalid zoom ranges, and minzoom > maxzoom. Print PASS lines consistent with existing test style. AI!

-- Add one fixture-driven test that parses `shared/fixtures/specs/minimal-clear.json` and `shared/fixtures/specs/fill-layer.json` via parser module and asserts validator accepts both. AI!