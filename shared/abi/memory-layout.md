# Memory Layout Specification

**Version:** 0.1.0  
**Last Updated:** 2026-03-06  
**Status:** Draft

## Purpose

This document defines the binary memory layout contract between the browser host (JavaScript) and the generated WebAssembly module.

The shared memory allows for data exchange, characterized by:

*   CPU-side buffers exchanged between JS and Wasm memory are passed by offset and length.
*   Little-endian encoding.
*   4-byte aligned minimum.
*   Explicit versioned structs for externally visible data.
*   Array data represented by `{ptr, len}` pairs.
*   Optional values via sentinel or explicit flag.

Key memory structures include:
*   Module header
*   Host capability block
*   Diagnostics ring header
*   Command stream header
*   Optional stats block

