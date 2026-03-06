// Memory utilities

export class MemoryView {
    constructor(memory) {
        this.memory = memory;
        this.u8 = new Uint8Array(memory.buffer);
        this.u32 = new Uint32Array(memory.buffer);
        this.f32 = new Float32Array(memory.buffer);
        this.view = new DataView(memory.buffer);
    }

    alignPtr(ptr, alignment) {
        return (ptr + alignment - 1) & ~(alignment - 1);
    }

    readU32(ptr) {
        return this.view.getUint32(ptr, true); // true for little-endian
    }

    writeU32(ptr, value) {
        this.view.setUint32(ptr, value, true);
    }

    readString(ptr, len) {
        const bytes = this.u8.subarray(ptr, ptr + len);
        return new TextDecoder('utf-8').decode(bytes);
    }

    writeString(ptr, str) {
        const bytes = new TextEncoder().encode(str);
        const len = bytes.length;
        this.u8.set(bytes, ptr);
        return len;
    }
}
