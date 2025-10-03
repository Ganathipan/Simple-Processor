// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// instructionCache.v - Instruction Cache Implementation
// Purpose: Implements a direct-mapped instruction cache for high-performance
//          instruction fetching. Provides CPU-cache interface with block-level
//          fetching from main memory for improved instruction bandwidth.
// -----------------------------------------------------------------------------

// Instruction Cache Module - High-performance instruction caching system
// Direct-mapped cache optimized for instruction fetch patterns
// 8 blocks × 16 bytes per block = 128 bytes total capacity
// Fetches 4 instructions (16 bytes) per cache line for spatial locality
module inst_cache(
    // CPU Interface Signals
    input wire clock,               // System clock
    input wire reset,               // Cache reset signal  
    input wire [31:0] address,      // 32-bit instruction address from PC
    output reg [31:0] readdata,     // 32-bit instruction word to CPU
    output reg busywait,            // CPU stall signal during cache miss
    
    // Instruction Memory Interface Signals
    output reg mem_read,            // Memory read request
    output reg [5:0] mem_address,   // 6-bit block address to memory
    input wire [127:0] mem_readdata,// 128-bit block data from memory (4 instructions)
    input wire mem_busywait         // Memory busy signal
);

// -----------------------
// Cache storage arrays
// -----------------------
reg [127:0] data_array [7:0]; // 8 blocks of 16 bytes
reg [20:0]  tag_array [7:0];  // Tag = upper 21 bits
reg         valid_array [7:0];

// -----------------------
// Address breakdown
// -----------------------
// 32-bit byte address: [31:0]
// block offset bits: [3:0]
// index bits: [6:4] (3 bits to select 8 lines)
// tag bits: [31:11] (upper bits)
wire [2:0] index = address[6:4];
wire [3:0] offset = address[3:0];
wire [25:0] tag = address[31:7];

// -----------------------
// Cache line signals
// -----------------------
reg [127:0] block_data;
reg [20:0]  stored_tag;
reg         stored_valid;

// internal control signals
reg hit;
reg miss;
reg [31:0] selected_word;

// FSM state
localparam IDLE = 1'b0;
localparam MEM_READ = 1'b1;
reg state;

integer i;

// -----------------------
// Asynchronous indexing with artificial latency
// -----------------------
always @(*) begin
    // indexing latency
    #1;
    block_data <= data_array[index];
    stored_tag <= tag_array[index];
    stored_valid <= valid_array[index];
end

// -----------------------
// Tag comparison + hit detection
// -----------------------
always @(*) begin
   // tag comparison latency
    hit <= #0.9 (stored_valid && (stored_tag == tag));
    miss <= !hit;
end

// -----------------------
// Word selection
// -----------------------
always @(*) begin
    // selection latency
    case (offset[3:2])
        2'b00: selected_word <= #1 block_data[31:0];
        2'b01: selected_word <= #1 block_data[63:32];
        2'b10: selected_word <= #1 block_data[95:64];
        2'b11: selected_word <= #1 block_data[127:96];
    endcase
    // readdata <= selected_word; // Update output
end

// -----------------------
// Main FSM
// -----------------------
always @(posedge clock, posedge reset) begin
    if (reset) begin
        // Invalidate cache
        for (i=0;i<8;i=i+1) begin
            valid_array[i] <= 0;
        end
        busywait <= 0;
        mem_read <= 0;
        state <= IDLE;
        readdata <= 32'b0;
    end
    else begin
        case (state)
            IDLE: begin
                if (hit) begin
                    //busywait <= 0;
                    readdata <= selected_word;
                end
                else begin
                    // Miss detected
                    busywait <= 1;
                    mem_read <= 1;
                    mem_address <= {address[9:4]}; // 6-bit block address
                    state <= MEM_READ;
                end
            end

            MEM_READ: begin
                // Wait for memory to finish
                if (!mem_busywait) begin
                    mem_read <= 0;
                    // Write fetched block to cache with latency
                    data_array[index] <= #1 mem_readdata;
                    tag_array[index] <= #1 tag;
                    valid_array[index] <= #1 1;
                    
                    // latency before serving
                    //#1.9 busywait <= 0; // Clear busywait
                    busywait <= 0; // Clear busywait
                    state <= IDLE;
                end
            end
        endcase
    end
end
endmodule
