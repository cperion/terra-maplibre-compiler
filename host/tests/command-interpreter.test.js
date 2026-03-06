
// Unit tests for CommandInterpreter
import assert from 'assert';
import CommandInterpreter from '../js/command-interpreter.js';
import { ResourceManager } from '../js/resource-tables.js';

// Mock WebGL2 Context
class MockWebGLContext {
    constructor() {
        this.calls = [];
        this.ARRAY_BUFFER = 0x8892;
        this.ELEMENT_ARRAY_BUFFER = 0x8893;
        this.STATIC_DRAW = 0x88E4;
        this.FLOAT = 0x1406;
    }
    createBuffer() { return { id: Math.random() }; }
    bindBuffer(target, buffer) { this.calls.push(['bindBuffer', target, buffer]); }
    bufferData(target, size, usage) { this.calls.push(['bufferData', target, size, usage]); }
    bufferSubData(target, offset, data) { this.calls.push(['bufferSubData', target, offset, data]); }
    deleteBuffer(buffer) { this.calls.push(['deleteBuffer', buffer]); }
    createProgram() { return { id: Math.random() }; }
    useProgram(program) { this.calls.push(['useProgram', program]); }
    deleteProgram(program) { this.calls.push(['deleteProgram', program]); }
    enableVertexAttribArray(index) { this.calls.push(['enableVertexAttribArray', index]); }
    vertexAttribPointer(index, size, type, normalized, stride, offset) { 
        this.calls.push(['vertexAttribPointer', index, size, type, normalized, stride, offset]); 
    }
    drawArrays(mode, first, count) { this.calls.push(['drawArrays', mode, first, count]); }
    drawElements(mode, count, type, offset) { this.calls.push(['drawElements', mode, count, type, offset]); }
    clearColor(r,g,b,a) { this.calls.push(['clearColor', r,g,b,a]); }
    clear(mask) { this.calls.push(['clear', mask]); }
    flush() { this.calls.push(['flush']); }
}

// Test Suite
async function runTests() {
    console.log("Running CommandInterpreter tests...");

    // Setup
    const memory = new WebAssembly.Memory({ initial: 1 });
    const gl = new MockWebGLContext();
    const resources = new ResourceManager();
    const interpreter = new CommandInterpreter(gl, memory, resources);
    const view = new DataView(memory.buffer);

    // Test 1: Basic Frame (Begin/End)
    {
        // Magic
        view.setUint32(0, 0x46524D45, true); 
        // Version 0.1
        view.setUint16(4, 0, true);
        view.setUint16(6, 1, true);
        // Frame ID 1
        view.setUint32(8, 1, true);
        // Command Count: 2 (Begin, End)
        view.setUint32(12, 2, true);

        // Command 1: BEGIN_FRAME (0x0001)
        view.setUint16(24, 0x0001, true);
        view.setUint16(26, 4, true); // Size

        // Command 2: END_FRAME (0x0002)
        view.setUint16(28, 0x0002, true);
        view.setUint16(30, 4, true); // Size

        interpreter.execute(0, 32);
        assert.deepStrictEqual(gl.calls.pop(), ['flush']);
        console.log("PASS: Basic Frame");
    }

    // Test 2: Buffer Lifecycle
    {
        gl.calls = [];
        // Magic
        view.setUint32(0, 0x46524D45, true); 
        view.setUint32(12, 1, true); // 1 command

        // CREATE_BUFFER (0x0005)
        // Header
        view.setUint16(24, 0x0005, true);
        view.setUint16(26, 12, true); // 4 + 8 payload
        // Payload: id=100, size=1024
        view.setUint32(28, 100, true);
        view.setUint32(32, 1024, true);

        interpreter.execute(0, 40);
        
        const buf = resources.buffers.get(100);
        assert(buf, "Buffer should be created in resources");
        const call = gl.calls.find(c => c[0] === 'bufferData');
        assert(call, "bufferData should be called");
        assert.strictEqual(call[2], 1024);
        console.log("PASS: Create Buffer");
    }

    // Test 3: Validation Error
    {
        try {
            // Bad magic
            view.setUint32(0, 0xDEADBEEF, true);
            interpreter.execute(0, 100);
            assert.fail("Should throw on invalid magic");
        } catch (e) {
            assert(e.message.includes("Invalid FrameHeader magic"));
            console.log("PASS: Magic Validation");
        }
    }
}

runTests().catch(e => {
    console.error("FAILED:", e);
    process.exit(1);
});
