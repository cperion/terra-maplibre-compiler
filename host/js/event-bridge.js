// Event bridge

export class EventBridge {
    constructor(wasmInstance) {
        this.exports = wasmInstance.exports;
        this.handlers = new Map();
        this.isDragging = false;
        this.lastX = 0;
        this.lastY = 0;
    }

    attach(element) {
        const events = [
            'mousedown', 'mouseup', 'mousemove', 'wheel', 
            'keydown', 'keyup',
            'touchstart', 'touchend', 'touchmove'
        ];
        
        events.forEach(eventType => {
            const handler = (e) => this.handleEvent(eventType, e, element);
            this.handlers.set(eventType, handler);
            element.addEventListener(eventType, handler, { passive: false });
        });
    }

    toQ16(v) {
        return Math.floor(v * 65536);
    }

    handleEvent(type, event, element) {
        if (!this.exports) return;

        const rect = element.getBoundingClientRect();
        let clientX = 0, clientY = 0;
        
        // Normalize touch/mouse coords
        if (type.startsWith('touch')) {
            if (event.touches.length > 0) {
                clientX = event.touches[0].clientX;
                clientY = event.touches[0].clientY;
            } else if (event.changedTouches.length > 0) {
                clientX = event.changedTouches[0].clientX;
                clientY = event.changedTouches[0].clientY;
            }
        } else {
            clientX = event.clientX;
            clientY = event.clientY;
        }

        const x = clientX - rect.left;
        const y = clientY - rect.top;
        const xQ16 = this.toQ16(x);
        const yQ16 = this.toQ16(y);
        
        // Modifiers mask: 1=Shift, 2=Ctrl, 4=Alt, 8=Meta
        let mods = 0;
        if (event.shiftKey) mods |= 1;
        if (event.ctrlKey) mods |= 2;
        if (event.altKey) mods |= 4;
        if (event.metaKey) mods |= 8;
        
        // Buttons: 1=Left, 2=Right, 4=Middle
        const buttons = event.buttons || 0;

        switch (type) {
            case 'mousedown':
            case 'touchstart':
                this.isDragging = true;
                this.lastX = x;
                this.lastY = y;
                if (this.exports.pointer_down) {
                    this.exports.pointer_down(xQ16, yQ16, buttons, mods);
                }
                break;
                
            case 'mouseup':
            case 'touchend':
                this.isDragging = false;
                if (this.exports.pointer_up) {
                    this.exports.pointer_up(xQ16, yQ16, buttons, mods);
                }
                break;
                
            case 'mousemove':
            case 'touchmove':
                if (type === 'touchmove') event.preventDefault();
                if (this.exports.pointer_move) {
                    this.exports.pointer_move(xQ16, yQ16, buttons, mods);
                }
                this.lastX = x;
                this.lastY = y;
                break;
                
            case 'wheel':
                event.preventDefault();
                const dxQ16 = this.toQ16(event.deltaX);
                const dyQ16 = this.toQ16(event.deltaY);
                if (this.exports.wheel) {
                    this.exports.wheel(dxQ16, dyQ16, mods);
                }
                break;
                
            case 'keydown':
                if (this.exports.key_event) {
                    this.exports.key_event(event.keyCode, 1, mods);
                }
                break;
                
            case 'keyup':
                if (this.exports.key_event) {
                    this.exports.key_event(event.keyCode, 0, mods);
                }
                break;
        }
    }

    detach(element) {
        this.handlers.forEach((handler, type) => {
            element.removeEventListener(type, handler);
        });
        this.handlers.clear();
    }
}
