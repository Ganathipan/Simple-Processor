/*
Module      : Instruction Cache
Author      : [Your Name]
Date        : [Date]

Description :
Instruction Cache for CO224 Lab 6 Part 3
Direct-mapped, 8 blocks of 16 Bytes each.
Handles instruction fetches with artificial latencies and CPU stalling.
*/

module inst_cache(
    input wire clock,
    input wire reset,
    input wire [31:0] address,      // Full byte address
    output reg [31:0] readdata,   // Fetched instruction word
    output reg busywait,     // CPU stall signal
    // interface to instruction memory
    output reg mem_read,
    output reg [5:0] mem_address,
    input wire [127:0] mem_readdata,
    input wire mem_busywait
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
    readdata <= selected_word; // Update output
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
                    readdata <= selected_word; // word selection happens again automatically
                    busywait = #1 0; // Clear busywait
                    state <= IDLE;
                end
            end
        endcase
    end
end
endmodule
