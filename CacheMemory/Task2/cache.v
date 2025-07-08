`timescale 1ns/100ps

module data_cache(
    input clk,
    input reset,
    input read,
    input write,
    input [7:0] address,
    input [7:0] writedata,
    output reg [7:0] readdata,
    output reg busywait,

    // Memory interface
    output reg mem_read,
    output reg mem_write,
    output reg [5:0] mem_address,
    output reg [31:0] mem_writedata,
    input [31:0] mem_readdata,
    input mem_busywait
);

// Tag: 5 bits, Valid:1, Dirty:1, Data:4x8 bits
reg [4:0] tags [0:7];
reg valids [0:7];
reg dirtys [0:7];
reg [31:0] data_blocks [0:7]; // 4 bytes per block

// State encoding
localparam IDLE = 3'b000;
localparam MEM_READ = 3'b001;
localparam MEM_WRITE = 3'b010;
localparam FETCH = 3'b011;
localparam WRITE_BACK = 3'b100;
reg [2:0] state;

// Address decomposition
wire [4:0] addr_tag = address[7:3];
wire [2:0] addr_index = address[2:0];
wire [1:0] addr_offset = address[1:0];

// Internal flags
reg hit, miss, dirty, valid;
reg [31:0] fetched_block;
integer i;

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