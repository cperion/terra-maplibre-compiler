
-- Create Terra module that generates Wasm

import "compiler.terra.renderer"

-- Exports
terra init() : int32
    -- Initialize state
    state.zoom_q16 = 65536 -- 1.0
    return 0
end

terra frame(time_ms : double) : int32
    render_frame(time_ms)
    -- In real impl: submit_commands(ptr, len)
    return 0
end

terra resize(w : int32, h : int32, dpr : int32) : int32
    state.width = w
    state.height = h
    state.dpr_q16 = dpr
    return 0
end

-- Stubs for other exports
terra pointer_move(x : int32, y : int32, b : int32, m : int32) : int32 return 0 end
terra pointer_down(x : int32, y : int32, b : int32, m : int32) : int32 return 0 end
terra pointer_up(x : int32, y : int32, b : int32, m : int32) : int32 return 0 end
terra wheel(dx : int32, dy : int32, m : int32) : int32 return 0 end
terra key_event(c : int32, d : int32, m : int32) : int32 return 0 end
terra resource_loaded(id : int32, s : int32, p : int32, l : int32) : int32 return 0 end
terra resource_failed(id : int32, s : int32) : int32 return 0 end

-- To compile this to Wasm, we would use terra.saveobj
-- saveobj("map.wasm", {
--   init = init, frame = frame, resize = resize, ...
-- })
