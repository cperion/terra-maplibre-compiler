// Event bridge

export class EventBridge {
    constructor(wasmModule) {
        this.wasmModule = wasmModule;
        this.handlers = new Map();
    }

    attach(element) {
        // Forward standard events to Wasm
        const events = ['mousedown', 'mouseup', 'mousemove', 'wheel', 'keydown', 'keyup'];
        
        events.forEach(eventType => {
            const handler = (e) => this.handleEvent(eventType, e);
            this.handlers.set(eventType, handler);
            element.addEventListener(eventType, handler);
        });
    }

    handleEvent(type, event) {
        if (!this.wasmModule.exports) return;

        // Map event types to integer codes expected by Wasm
        // This is a placeholder mapping; real implementation would match ABI
        const eventCodes = {
            'mousedown': 1,
            'mouseup': 2,
            'mousemove': 3,
            'wheel': 4,
            'keydown': 5,
            'keyup': 6
        };

        const code = eventCodes[type] || 0;
        // Assume wasm export on_event(code, x, y)
        if (this.wasmModule.exports.on_event) {
             this.wasmModule.exports.on_event(code, event.clientX || 0, event.clientY || 0);
        }
    }

    detach(element) {
        this.handlers.forEach((handler, type) => {
            element.removeEventListener(type, handler);
        });
        this.handlers.clear();
    }
}
