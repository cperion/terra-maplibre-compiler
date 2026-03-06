// Command interpreter

import { ResourceManager } from './resource-tables.js';
import { compileShader, createProgram } from './webgl-utils.js';

export default class CommandInterpreter {
    constructor(gl, memory, resources) {
        this.gl = gl;
        this.memory = memory;
        this.resources = resources;
        this.view = null;
    }

    execute(ptr, len) {
        this.validateCommandStream(ptr, len);
        this.view = new DataView(this.memory.buffer);

        const magic = this.readU32(ptr);
        const version_major = this.readU16(ptr + 4);
        const version_minor = this.readU16(ptr + 6);
        const frame_id = this.readU32(ptr + 8);
        const command_count = this.readU32(ptr + 12);

        let offset = ptr + 24;

        for (let i = 0; i < command_count; i++) {
            const opcode = this.readU16(offset);
            const size = this.readU16(offset + 2);
            const payloadOffset = offset + 4;

            this.dispatchCommand(opcode, payloadOffset);

            offset += size;
        }
    }

    dispatchCommand(opcode, p) {
        const gl = this.gl;

        switch (opcode) {
            case 0x0001: // BEGIN_FRAME
                break;

            case 0x0002: // END_FRAME
                gl.flush();
                break;

            case 0x0003: // CLEAR
                const r = this.readU8(p);
                const g = this.readU8(p + 1);
                const b = this.readU8(p + 2);
                const a = this.readU8(p + 3);
                const depth = this.readF32(p + 4);
                const stencil = this.readU8(p + 8);
                const flags = this.readU8(p + 9);
                
                gl.clearColor(r/255.0, g/255.0, b/255.0, a/255.0);
                gl.clearDepth(depth);
                gl.clearStencil(stencil);

                let mask = 0;
                if (flags & 1) mask |= gl.COLOR_BUFFER_BIT;
                if (flags & 2) mask |= gl.DEPTH_BUFFER_BIT;
                if (flags & 4) mask |= gl.STENCIL_BUFFER_BIT;
                
                gl.clear(mask);
                break;

            case 0x0004: // USE_PROGRAM
                const progId = this.readU32(p);
                const program = this.resources.programs.get(progId);
                if (program) {
                    gl.useProgram(program);
                }
                break;

            case 0x0005: // CREATE_BUFFER
                const bufId = this.readU32(p);
                const size = this.readU32(p + 4);
                
                const buf = gl.createBuffer();
                this.resources.buffers.set(bufId, buf);
                
                gl.bindBuffer(gl.ARRAY_BUFFER, buf);
                gl.bufferData(gl.ARRAY_BUFFER, size, gl.STATIC_DRAW);
                gl.bindBuffer(gl.ARRAY_BUFFER, null);
                break;

            case 0x0006: // UPLOAD_BUFFER
                const upBufId = this.readU32(p);
                const upOffset = this.readU32(p + 4);
                const dataPtr = this.readU32(p + 8);
                const dataLen = this.readU32(p + 12);

                const upBuf = this.resources.buffers.get(upBufId);
                if (upBuf) {
                    gl.bindBuffer(gl.ARRAY_BUFFER, upBuf);
                    const data = new Uint8Array(this.memory.buffer, dataPtr, dataLen);
                    gl.bufferSubData(gl.ARRAY_BUFFER, upOffset, data);
                    gl.bindBuffer(gl.ARRAY_BUFFER, null);
                }
                break;

            case 0x0007: // BIND_VERTEX_BUFFER
                const slot = this.readU32(p);
                const bindBufId = this.readU32(p + 4);
                const stride = this.readU32(p + 8);
                const bindOffset = this.readU32(p + 12);
                
                const bindBuf = this.resources.buffers.get(bindBufId);
                if (bindBuf) {
                    gl.bindBuffer(gl.ARRAY_BUFFER, bindBuf);
                    gl.enableVertexAttribArray(slot);
                    gl.vertexAttribPointer(slot, 3, gl.FLOAT, false, stride, bindOffset);
                }
                break;

            case 0x0008: // BIND_INDEX_BUFFER
                const idxBufId = this.readU32(p);
                const idxBuf = this.resources.buffers.get(idxBufId);
                if (idxBuf) {
                    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, idxBuf);
                }
                break;

            case 0x0009: // SET_VIEWPORT
                const x = this.readI32(p);
                const y = this.readI32(p + 4);
                const w = this.readU32(p + 8);
                const h = this.readU32(p + 12);
                gl.viewport(x, y, w, h);
                break;

            case 0x000A: // SET_BLEND_STATE
                const enabled = this.readU8(p);
                if (enabled) {
                    gl.enable(gl.BLEND);
                    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
                } else {
                    gl.disable(gl.BLEND);
                }
                break;

            case 0x000B: // SET_UNIFORM_BLOCK
                const progIdUB = this.readU32(p);
                const blockIndex = this.readU32(p + 4);
                const dataPtrUB = this.readU32(p + 8);
                const dataLenUB = this.readU32(p + 12);
                
                const progUB = this.resources.programs.get(progIdUB);
                if (progUB) {
                    gl.useProgram(progUB);
                    const uniformData = new Uint8Array(this.memory.buffer, dataPtrUB, dataLenUB);
                    // Note: Full UBO support would require gl.uniformBlockBinding + buffer
                }
                break;

            case 0x000C: // DRAW_INDEXED
                const mode = this.readU32(p);
                const count = this.readU32(p + 4);
                const type = this.readU32(p + 8);
                const iOffset = this.readU32(p + 12);
                gl.drawElements(mode, count, type, iOffset);
                break;

            case 0x000D: // DRAW_ARRAYS
                const dMode = this.readU32(p);
                const dFirst = this.readU32(p + 4);
                const dCount = this.readU32(p + 8);
                gl.drawArrays(dMode, dFirst, dCount);
                break;

            case 0x000E: // DESTROY_BUFFER
                const delBufId = this.readU32(p);
                const delBuf = this.resources.buffers.delete(delBufId);
                if (delBuf) {
                    gl.deleteBuffer(delBuf);
                }
                break;

            case 0x000F: // DESTROY_PROGRAM
                const killProgId = this.readU32(p);
                const killProg = this.resources.programs.delete(killProgId);
                if (killProg) {
                    gl.deleteProgram(killProg);
                }
                break;

            case 0x0010: // CREATE_TEXTURE
                const texId = this.readU32(p);
                const width = this.readU32(p + 4);
                const height = this.readU32(p + 8);
                const format = this.readU32(p + 12);
                
                const tex = gl.createTexture();
                gl.bindTexture(gl.TEXTURE_2D, tex);
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
                gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
                gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
                gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
                gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
                
                this.resources.textures.set(texId, tex);
                break;

            case 0x0011: // CREATE_PROGRAM
                const newProgId = this.readU32(p);
                const vsPtr = this.readU32(p + 4);
                const vsLen = this.readU32(p + 8);
                const fsPtr = this.readU32(p + 12);
                const fsLen = this.readU32(p + 16);
                
                const vsSource = this.readString(vsPtr, vsLen);
                const fsSource = this.readString(fsPtr, fsLen);
                
                try {
                    const vs = compileShader(gl, gl.VERTEX_SHADER, vsSource);
                    const fs = compileShader(gl, gl.FRAGMENT_SHADER, fsSource);
                    const prog = createProgram(gl, vs, fs);
                    this.resources.programs.set(newProgId, prog);
                    gl.deleteShader(vs);
                    gl.deleteShader(fs);
                } catch (err) {
                    console.error('Failed to create program:', err);
                }
                break;

            case 0x0012: // DESTROY_TEXTURE
                const killTexId = this.readU32(p);
                const killTex = this.resources.textures.delete(killTexId);
                if (killTex) {
                    gl.deleteTexture(killTex);
                }
                break;

            default:
                console.warn(`Unknown opcode: 0x${opcode.toString(16).padStart(4, '0')}`);
        }
    }

    validateCommandStream(ptr, len) {
        if (ptr % 4 !== 0) throw new Error("Command stream pointer not aligned");
        if (ptr + len > this.memory.buffer.byteLength) throw new Error("Command stream out of bounds");
        
        const view = new DataView(this.memory.buffer);
        const magic = view.getUint32(ptr, true);
        if (magic !== 0x46524D45) throw new Error("Invalid FrameHeader magic");
    }

    readU8(ptr) { return this.view.getUint8(ptr); }
    readU16(ptr) { return this.view.getUint16(ptr, true); }
    readU32(ptr) { return this.view.getUint32(ptr, true); }
    readI32(ptr) { return this.view.getInt32(ptr, true); }
    readF32(ptr) { return this.view.getFloat32(ptr, true); }

    readString(ptr, len) {
        const bytes = new Uint8Array(this.memory.buffer, ptr, len);
        return new TextDecoder('utf-8').decode(bytes);
    }
}
