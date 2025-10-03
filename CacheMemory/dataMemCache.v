// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// dataMemCache.v - Data Cache Implementation
// Purpose: Implements a direct-mapped data cache with write-back policy for
//          improved memory access performance. Provides CPU-cache interface
//          and cache-memory interface with proper bus protocols.
// -----------------------------------------------------------------------------

//`timescale 1ns/100ps

// Data Cache Module - High-performance data caching system
// Direct-mapped cache with write-back policy to reduce memory traffic
// 8 cache lines × 4 bytes per line = 32 bytes total capacity
module data_cache(
    // CPU Interface Signals
    input clk,                      // System clock
    input reset,                    // Cache reset signal
    input read,                     // CPU read request
    input write,                    // CPU write request  
    input [7:0] address,            // 8-bit byte address from CPU
    input [7:0] writedata,          // 8-bit data from CPU for writes
    output reg [7:0] readdata,      // 8-bit data to CPU for reads
    output reg busywait,            // CPU stall signal during cache miss

    // Main Memory Interface Signals
    output reg mem_read,            // Memory read request
    output reg mem_write,           // Memory write request
    output reg [5:0] mem_address,   // 6-bit block address to memory
    output reg [31:0] mem_writedata,// 32-bit block data to memory
    input [31:0] mem_readdata,      // 32-bit block data from memory
    input mem_busywait              // Memory busy signal
);

// Cache Storage Arrays - Direct-mapped cache organization
reg [2:0] tags [0:7];           // Tag array: 3-bit tags for 8 cache lines
reg valids [0:7];               // Valid bit array: indicates if cache line contains valid data
reg dirtys [0:7];               // Dirty bit array: indicates if cache line was modified
reg [31:0] data_blocks [0:7];   // Data array: 4 bytes per block × 8 blocks

// Cache Controller FSM State Encoding
localparam IDLE = 3'b000;       // Idle state: ready for new CPU requests
localparam MEM_READ = 3'b001;   // Memory read state: unused in current implementation
localparam MEM_WRITE = 3'b010;  // Memory write state: unused in current implementation  
localparam FETCH = 3'b011;      // Fetch state: loading cache line from memory
localparam WRITE_BACK = 3'b100; // Write-back state: evicting dirty cache line to memory
reg [2:0] state;                // Current FSM state

// Address Decomposition for Direct-Mapped Cache
reg [2:0] addr_tag;             // Upper 3 bits: cache line tag
reg [2:0] addr_index;           // Middle 3 bits: cache line index (0-7)
reg [1:0] addr_offset;          // Lower 2 bits: byte offset within cache line (0-3)

// Extract address fields from CPU address
always @(*) begin 
    addr_tag <= address[7:5];   // Tag field for cache line identification
    addr_index <= address[4:2]; // Index field for cache line selection
    addr_offset <= address[1:0]; // Offset field for byte selection within line
end

// Cache Control Flags and Temporary Storage
reg hit, miss, dirty, valid;   // Cache status flags
reg [31:0] fetched_block;       // Temporary storage for fetched cache line
integer i;                      // Loop variable for cache initialization

// Async hit detection logic
always @(*) begin
    // Initial busywait
    busywait = (read || write);

    // Artificial index delay
    #1;
    valid = valids[addr_index];
    dirty = dirtys[addr_index];
    #0.9;
    hit = valid && (tags[addr_index] == addr_tag);
    miss = !hit;
end

// Data read logic Asynchornously
always @(*) begin
    if (read && hit) begin
        #1;
        case(addr_offset)
            2'b00: readdata = data_blocks[addr_index][7:0];
            2'b01: readdata = data_blocks[addr_index][15:8];
            2'b10: readdata = data_blocks[addr_index][23:16];
            2'b11: readdata = data_blocks[addr_index][31:24];
        endcase
        busywait = 0;  // Deassert busywait on hit
    end
end

// FSM
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        mem_read <= 0;
        mem_write <= 0;
        busywait <= 0;
        readdata <= 0;

        // Invalidate cache
        
        for (i=0;i<8;i=i+1) begin
            valids[i] <= 0;
            dirtys[i] <= 0;
            tags[i] <= 0;
            data_blocks[i] <= 0;
        end
    end else begin
        case(state)
        IDLE: begin
            if ((read || write) && miss) begin
                if (dirty) begin
                    // Write-back required
                    mem_write <= 1;
                    mem_read <= 0;
                    mem_address <= {tags[addr_index], addr_index};
                    mem_writedata <= data_blocks[addr_index];
                    state <= WRITE_BACK;
                end else begin
                    // Fetch from memory
                    mem_read <= 1;
                    mem_write <= 0;
                    mem_address <= {addr_tag, addr_index};
                    state <= FETCH;
                end
            end else if ((read || write) && hit) begin
                busywait <= 0; // Deassert busywait on hit
                if (write) begin
                    // Write the byte
                    case(addr_offset)
                        2'b00: data_blocks[addr_index][7:0] <= writedata;
                        2'b01: data_blocks[addr_index][15:8] <= writedata;
                        2'b10: data_blocks[addr_index][23:16] <= writedata;
                        2'b11: data_blocks[addr_index][31:24] <= writedata;
                    endcase
                    dirtys[addr_index] <= 1;
                end
            end
        end

        WRITE_BACK: begin
            if (~mem_busywait) begin
                mem_write <= 0;
                // Start fetching the new block
                mem_read <= 1;
                mem_address <= {addr_tag, addr_index};
                state <= FETCH;
            end
        end

        FETCH: begin
            if (~mem_busywait) begin
                mem_read <= 0;
                // Store fetched block
                data_blocks[addr_index] <= mem_readdata;
                tags[addr_index] <= addr_tag;
                valids[addr_index] <= 1;
                dirtys[addr_index] <= 0;
                state <= IDLE;
            end
        end
        endcase
    end
end
endmodule