
-- Implement command stream builder in Terra

-- Mock implementation of command stream writing
-- In real Terra code, this would write to a pointer into the linear memory arena

terra cmd_begin_frame()
    -- write header, reset offsets
end

terra cmd_end_frame()
    -- finalize header count
end

terra cmd_clear(r : uint8, g : uint8, b : uint8, a : uint8, depth : float, stencil : uint8, flags : uint8)
    -- emit opcode 0x0003 and payload
end

terra cmd_create_buffer(id : uint32, size : uint32)
end

terra cmd_upload_buffer(id : uint32, offset : uint32, ptr : &opaque, len : uint32)
end
