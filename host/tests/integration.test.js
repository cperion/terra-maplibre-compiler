
// Integration test
import assert from 'assert';
import Host from '../js/host.js';
import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Mock browser environment globals for Node.js
global.performance = { now: () => Date.now() };
global.requestAnimationFrame = (cb) => setTimeout(cb, 16);
global.cancelAnimationFrame = (id) => clearTimeout(id);
global.TextDecoder = class { decode(arr) { return Buffer.from(arr).toString('utf8'); } };
global.TextEncoder = class { encode(str) { return Buffer.from(str, 'utf8'); } };
global.window = { devicePixelRatio: 1.0 };
global.fetch = async (path) => {
    // For test, load local file
    try {
        const buffer = readFileSync(path);
        return {
            ok: true,
            status: 200,
            arrayBuffer: async () => buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength)
        };
    } catch (e) {
        return { ok: false, status: 404, statusText: e.message };
    }
};

// Mock WebGL
class MockCanvas {
    constructor() {
        this.width = 800;
        this.height = 600;
        this.clientWidth = 800;
        this.clientHeight = 600;
        this.listeners = {};
    }
    getContext(type) {
        if (type !== 'webgl2') return null;
        return {
            getExtension: () => ({ loseContext: () => {} }),
            createBuffer: () => ({}),
            deleteBuffer: () => {},
            bindBuffer: () => {},
            bufferData: () => {},
            bufferSubData: () => {},
            createProgram: () => ({}),
            deleteProgram: () => {},
            useProgram: () => {},
            createShader: () => ({}),
            shaderSource: () => {},
            compileShader: () => {},
            attachShader: () => {},
            linkProgram: () => {},
            getShaderParameter: () => true,
            getProgramParameter: () => true,
            clearColor: () => {},
            clear: () => {},
            flush: () => {},
            viewport: () => {},
            enable: () => {},
            disable: () => {},
            blendFunc: () => {},
            getError: () => 0,
            NO_ERROR: 0,
            ARRAY_BUFFER: 0x8892
        };
    }
    addEventListener(type, cb) { this.listeners[type] = cb; }
    removeEventListener(type, cb) { delete this.listeners[type]; }
}

async function runIntegration() {
    console.log("Running Integration Test...");
    
    // Path to wasm - expect it to be built in examples/demo/map.wasm
    // We navigate from host/tests/ to examples/demo/
    const wasmPath = join(__dirname, '../../examples/demo/map.wasm');
    
    // Check if wasm exists
    try {
        readFileSync(wasmPath);
    } catch (e) {
        console.warn("Skipping integration test: map.wasm not found. Build it first.");
        return;
    }

    const canvas = new MockCanvas();
    const host = new Host(canvas);

    console.log("1. Loading Wasm...");
    await host.load(wasmPath);
    
    console.log("2. Initializing...");
    await host.initialize();
    
    assert(host.memory, "Memory should be initialized");
    assert(host._instance, "Wasm instance should be created");
    
    console.log("3. Resizing...");
    host.resize(1024, 768);
    
    console.log("4. Running frame...");
    // Mock requestAnimationFrame triggers automatically via stub above, 
    // but we check if frame export is callable
    host._instance.exports.frame(1000.0);
    
    console.log("5. Destroying...");
    host.destroy();
    
    console.log("PASS: Integration lifecycle complete");
}

runIntegration().catch(e => {
    console.error("FAILED:", e);
    process.exit(1);
});
