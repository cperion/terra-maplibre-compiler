// Host class implementation

import CommandInterpreter from './command-interpreter.js';
import { ResourceManager } from './resource-tables.js';

const INITIAL_MEMORY_PAGES = 256; // 16MB default
const MAX_MEMORY_PAGES = 1024;    // 64MB max

export default class Host {
    /**
     * @param {HTMLCanvasElement} canvas
     */
    constructor(canvas) {
        this._canvas = canvas;
        this._gl = canvas.getContext('webgl2', {
            antialias: false,
            alpha: true,
            premultipliedAlpha: true,
            preserveDrawingBuffer: false
        });

        if (!this._gl) {
            throw new Error("WebGL2 not supported");
        }

        this._wasmModule = null;
        this._instance = null;
        this._memory = null;
        this._commandInterpreter = null;
        this._resources = new ResourceManager();
        this._pendingFrame = null;

        // Camera state
        this._zoom = 1.0;
        this._centerX = 0.0;
        this._centerY = 0.0;
        this._accumulatedWheelY = 0;
    }

    get canvas() { return this._canvas; }
    get gl() { return this._gl; }
    get memory() { return this._memory; }
    get zoom() { return this._zoom; }
    get centerX() { return this._centerX; }
    get centerY() { return this._centerY; }

    setViewport(zoom, centerX, centerY) {
        this._zoom = zoom;
        this._centerX = centerX;
        this._centerY = centerY;
    }

    /**
     * @param {string} wasmPath
     */
    async load(wasmPath) {
        const response = await fetch(wasmPath);
        if (!response.ok) {
            throw new Error(`Failed to fetch Wasm module: ${response.status} ${response.statusText}`);
        }
        const bytes = await response.arrayBuffer();
        this._wasmModule = await WebAssembly.compile(bytes);
    }

    async initialize() {
        this._memory = new WebAssembly.Memory({
            initial: INITIAL_MEMORY_PAGES,
            maximum: MAX_MEMORY_PAGES,
            shared: false
        });

        this._commandInterpreter = new CommandInterpreter(this._gl, this._memory, this._resources);

        const imports = {
            env: {
                memory: this._memory,
                now_ms: () => performance.now(),
                
                log: (level, ptr, len) => {
                    const msg = this._readString(ptr, len);
                    if (level === 0) console.log(msg);
                    else if (level === 1) console.warn(msg);
                    else console.error(msg);
                },

                request_frame: () => {
                    if (!this._pendingFrame) {
                        this._pendingFrame = requestAnimationFrame(() => this._renderFrame());
                    }
                },

                canvas_size: (ptr) => {
                    const view = new DataView(this._memory.buffer);
                    view.setUint32(ptr, this._canvas.width, true);
                    view.setUint32(ptr + 4, this._canvas.height, true);
                },

                submit_commands: (ptr, len) => {
                    this._commandInterpreter.execute(ptr, len);
                },

                fetch_start: (req_id, url_ptr, url_len, kind) => {
                    const url = this._readString(url_ptr, url_len);
                    // console.log(`Fetch requested: ${url} (id=${req_id})`);
                    
                    fetch(url)
                        .then(response => {
                            if (!response.ok) throw new Error(`HTTP ${response.status}`);
                            return response.arrayBuffer();
                        })
                        .then(buffer => {
                            if (this._instance.exports.resource_loaded) {
                                // For now, passing 0, 0 just to trigger the callback
                                this._instance.exports.resource_loaded(req_id, 0, 0, 0); 
                            }
                        })
                        .catch(err => {
                            console.error(`Fetch failed for ${url}:`, err);
                            if (this._instance.exports.resource_failed) {
                                this._instance.exports.resource_failed(req_id, 1);
                            }
                        });
                },

                resource_release: (kind, handle) => {
                    if (kind === 0) { // Buffer
                        const buf = this._resources.buffers.delete(handle);
                        if (buf) this._gl.deleteBuffer(buf);
                    } else if (kind === 1) { // Program
                        const prog = this._resources.programs.delete(handle);
                        if (prog) this._gl.deleteProgram(prog);
                    } else if (kind === 2) { // Texture
                        const tex = this._resources.textures.delete(handle);
                        if (tex) this._gl.deleteTexture(tex);
                    }
                }
            }
        };

        this._instance = await WebAssembly.instantiate(this._wasmModule, imports);
        
        // Initial setup
        this._instance.exports.init();
        
        // Initial resize
        this.resize(this._canvas.clientWidth, this._canvas.clientHeight);
        
        // Initial frame
        this._renderFrame();
    }

    _renderFrame() {
        this._pendingFrame = null;
        if (this._instance && this._instance.exports.frame) {
            this._instance.exports.frame(performance.now());
        }
    }

    _readString(ptr, len) {
        const bytes = new Uint8Array(this._memory.buffer, ptr, len);
        return new TextDecoder('utf-8').decode(bytes);
    }

    /**
     * @param {number} width 
     * @param {number} height 
     */
    resize(width, height) {
        this._canvas.width = width;
        this._canvas.height = height;
        
        const dpr = window.devicePixelRatio || 1;
        const dprQ16 = Math.floor(dpr * 65536);
        
        if (this._instance && this._instance.exports.resize) {
            this._instance.exports.resize(width, height, dprQ16);
        }
    }

    destroy() {
        if (this._pendingFrame) {
            cancelAnimationFrame(this._pendingFrame);
        }
        const ext = this._gl.getExtension('WEBGL_lose_context');
        if (ext) ext.loseContext();
        
        this._instance = null;
        this._memory = null;
        this._commandInterpreter = null;
    }
}
