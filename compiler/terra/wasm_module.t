
-- Create Terra module that generates Wasm

import "compiler.terra.renderer"

-- Host Imports
-- Defined as extern functions that will be imported from "env" module in Wasm
local now_ms = terralib.externfunction("now_ms", {} -> double)
local log_fn = terralib.externfunction("log", {int32, int32, int32} -> {})
local request_frame = terralib.externfunction("request_frame", {} -> {})
local canvas_size = terralib.externfunction("canvas_size", {int32} -> {})
local submit_commands = terralib.externfunction("submit_commands", {int32, int32} -> {})
local fetch_start = terralib.externfunction("fetch_start", {int32, int32, int32, int32} -> {})
local resource_release = terralib.externfunction("resource_release", {int32, int32} -> {})

-- Exports
terra init() : int32
    -- Initialize state
    state.zoom_q16 = 65536 -- 1.0
    state.dpr_q16 = 65536
    renderer_init()
    return 0
end

terra frame(time_ms : double) : int32
    render_frame(time_ms)
    return 0
end

terra resize(w : int32, h : int32, dpr : int32) : int32
    state.width = w
    state.height = h
    state.dpr_q16 = dpr
    return 0
end

-- Input handling stubs (expanded for demo interaction later)
terra pointer_move(x : int32, y : int32, b : int32, m : int32) : int32 
    -- For now just request a frame to verify interaction loop
    request_frame()
    return 0 
end

terra pointer_down(x : int32, y : int32, b : int32, m : int32) : int32 
    return 0 
end

terra pointer_up(x : int32, y : int32, b : int32, m : int32) : int32 
    return 0 
end

terra wheel(dx : int32, dy : int32, m : int32) : int32 
    -- Simple zoom accumulation for demo
    state.zoom_q16 = state.zoom_q16 - dy
    if state.zoom_q16 < 65536 then state.zoom_q16 = 65536 end -- Min zoom 1.0
    request_frame()
    return 0 
end

terra key_event(c : int32, d : int32, m : int32) : int32 return 0 end
terra resource_loaded(id : int32, s : int32, p : int32, l : int32) : int32 return 0 end
terra resource_failed(id : int32, s : int32) : int32 return 0 end

-- Save Wasm Object
terralib.saveobj("map.wasm", {
    -- Exports
    init = init,
    frame = frame,
    resize = resize,
    pointer_move = pointer_move,
    pointer_down = pointer_down,
    pointer_up = pointer_up,
    wheel = wheel,
    key_event = key_event,
    resource_loaded = resource_loaded,
    resource_failed = resource_failed
}, {
    -- Link imports
    ["now_ms"] = now_ms,
    ["log"] = log_fn,
    ["request_frame"] = request_frame,
    ["canvas_size"] = canvas_size,
    ["submit_commands"] = submit_commands,
    ["fetch_start"] = fetch_start,
    ["resource_release"] = resource_release
})
