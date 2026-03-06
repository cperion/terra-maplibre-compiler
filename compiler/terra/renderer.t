-- Implement basic renderer in Terra

import "compiler.terra.command_stream"

-- Import host submission function (defined in wasm_module.t linking)
local host_submit_commands = terralib.externfunction("submit_commands", {int32, int32} -> {})

struct RendererState {
    width : uint32;
    height : uint32;
    dpr_q16 : int32;
    zoom_q16 : int32;
    center_x_q16 : int32;
    center_y_q16 : int32;
    frame_count : uint32;
}

global state : RendererState

terra render_background(r : uint8, g : uint8, b : uint8)
    -- Clear color (0x03)
    -- Flags: Color(1) | Depth(2) | Stencil(4) = 7 (clear all for safety)
    cmd_clear(r, g, b, 255, 1.0f, 0, 7)
end

terra render_frame(time_ms : double)
    state.frame_count = state.frame_count + 1
    
    cmd_begin_frame(state.frame_count)
    
    -- For demo: Vary background color slightly with time
    var phase = [int](time_ms / 20.0) % 255
    render_background(26, 26, [uint8](42 + (phase / 10))) 
    
    cmd_end_frame()
    
    -- Submit to host
    -- We pass the offset into linear memory where the frame arena starts
    -- and the length of data written
    host_submit_commands([int32](frame_arena), frame_arena_offset)
end

terra renderer_init()
    -- Initialize arena pointer (pointing to some free space in linear memory)
    -- In this simple setup, we put it at 1MB offset, assuming header/globals are small.
    -- Ideally, we'd use malloc if we linked libc, or a heap pointer.
    -- Casting integer 1MB to pointer.
    frame_arena = [&uint8](1024 * 1024) 
    state.frame_count = 0
end
