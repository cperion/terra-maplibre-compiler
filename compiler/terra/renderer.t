
-- Implement basic renderer in Terra

import "compiler.terra.command_stream"

struct RendererState {
    width : uint32;
    height : uint32;
    dpr_q16 : int32;
    zoom_q16 : int32;
    center_x_q16 : int32;
    center_y_q16 : int32;
}

global state : RendererState

terra render_background(r : uint8, g : uint8, b : uint8)
    -- Clear color (0x03)
    -- Flags: Color(1) | Depth(2) = 3
    cmd_clear(r, g, b, 255, 1.0f, 0, 3)
end

terra render_frame(time_ms : double)
    cmd_begin_frame()
    
    -- In a real implementation, we'd iterate the layer list
    -- For this demo, we hardcode a background clear
    render_background(26, 26, 42) -- #1a1a2a
    
    cmd_end_frame()
end
