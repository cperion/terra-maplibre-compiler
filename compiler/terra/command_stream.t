-- Implement command stream builder in Terra

-- Import standard C functions
local c = terralib.includec("string.h")

-- Global arena pointers (linked from renderer or main module)
-- For this simple implementation, we assume a fixed arena at a known offset or managed globally
-- In a real system, these would be managed by an allocator.
-- We'll define them here for the demo context.

-- 1MB frame arena for demo
local FRAME_ARENA_SIZE = 1024 * 1024 
global frame_arena : &uint8
global frame_arena_offset : uint32
global command_count : uint32

-- Helper to write values
terra write_u8(val : uint8)
    if frame_arena_offset + 1 > FRAME_ARENA_SIZE then return end
    @([&uint8](frame_arena + frame_arena_offset)) = val
    frame_arena_offset = frame_arena_offset + 1
end

terra write_u16(val : uint16)
    if frame_arena_offset + 2 > FRAME_ARENA_SIZE then return end
    @([&uint16](frame_arena + frame_arena_offset)) = val
    frame_arena_offset = frame_arena_offset + 2
end

terra write_u32(val : uint32)
    if frame_arena_offset + 4 > FRAME_ARENA_SIZE then return end
    @([&uint32](frame_arena + frame_arena_offset)) = val
    frame_arena_offset = frame_arena_offset + 4
end

terra write_float(val : float)
    if frame_arena_offset + 4 > FRAME_ARENA_SIZE then return end
    @([&float](frame_arena + frame_arena_offset)) = val
    frame_arena_offset = frame_arena_offset + 4
end

terra cmd_begin_frame(frame_id : uint32)
    -- Reset for new frame
    -- In a real allocator, we'd allocate a new block. Here we reset the linear buffer.
    frame_arena_offset = 0
    command_count = 0

    -- FrameHeader
    write_u32(0x46524D45) -- Magic 'FRME'
    write_u16(0)          -- Version Major
    write_u16(1)          -- Version Minor
    write_u32(frame_id)   -- Frame ID
    write_u32(0)          -- Command Count (placeholder, written at end)
    write_u32(0)          -- Flags
    write_u32(0)          -- Reserved
end

terra cmd_end_frame()
    -- Patch command count at offset 12
    @([&uint32](frame_arena + 12)) = command_count
end

terra cmd_clear(r : uint8, g : uint8, b : uint8, a : uint8, depth : float, stencil : uint8, flags : uint8)
    -- Opcode 0x0003
    write_u16(0x0003)
    -- Size: 4 (header) + 12 (payload + padding) = 16
    write_u16(16)
    
    -- Payload
    write_u8(r)
    write_u8(g)
    write_u8(b)
    write_u8(a)
    write_float(depth)
    write_u8(stencil)
    write_u8(flags)
    write_u16(0) -- Padding
    
    command_count = command_count + 1
end

terra cmd_create_buffer(id : uint32, size : uint32, usage : uint32)
    -- Opcode 0x0005
    write_u16(0x0005)
    -- Size: 4 + 12 = 16
    write_u16(16)
    
    write_u32(id)
    write_u32(size)
    write_u32(usage)
    
    command_count = command_count + 1
end

terra cmd_upload_buffer(id : uint32, offset : uint32, ptr : &opaque, len : uint32)
    -- Opcode 0x0006
    write_u16(0x0006)
    -- Size: 4 + 16 = 20
    write_u16(20)
    
    write_u32(id)
    write_u32(offset)
    write_u32([uint32](ptr)) -- Cast pointer to u32 offset (assuming shared memory base 0)
    write_u32(len)
    
    command_count = command_count + 1
end

terra cmd_draw_arrays(mode : uint32, first : uint32, count : uint32)
    -- Opcode 0x000D
    write_u16(0x000D)
    -- Size: 4 + 12 = 16
    write_u16(16)
    
    write_u32(mode)
    write_u32(first)
    write_u32(count)
    
    command_count = command_count + 1
end
