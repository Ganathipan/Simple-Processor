//`timescale 1ns/100ps

module inst_cache(
    input CLK,
    input RESET,
    input [31:0] PC,
    output reg [31:0] INSTRUCTION,
    output reg BUSYWAIT,

    // Memory interface
    output reg INST_MEM_READ,
    output reg [5:0] INST_MEM_ADDRESS,
    input [127:0] INST_MEM_DATA,
    input INST_MEM_BUSYWAIT
);

// Tag: 3bits, Valid:1, Data:4x32 bits
reg [24:0] tags [0:7];
reg valids [0:7];
reg [127:0] data_blocks [0:7]; // 16 bytes per block

// State encoding
localparam IDLE = 1'b0;
localparam FETCH = 1'b1;
reg state;

// Address decomposition
reg [24:0] addr_tag;
reg [2:0] addr_index;
reg [1:0] addr_offset;

always @(*) begin 
    #1;
    addr_tag <= PC[31:7];
    addr_index <= PC[6:4];
    addr_offset <= PC[3:2];
end

// Internal flags
reg hit, miss, valid;
integer i;

// Async hit detection logic
always @(posedge PC) begin
    // Initial busywait: active when READ is asserted
    BUSYWAIT = 1'b1;

    // Artificial index delay
    #1;
    valid = valids[addr_index];

    // Artificial tag comparison latency
    #0.9;
    hit = valid && (tags[addr_index] == addr_tag);
    miss = !hit;
end

// Data read logic Asynchronously
always @(*) begin
    if (BUSYWAIT && hit) begin
        #1;
        case(addr_offset)
            2'b00: INSTRUCTION = data_blocks[addr_index][127:96];
            2'b01: INSTRUCTION = data_blocks[addr_index][95:64];
            2'b10: INSTRUCTION = data_blocks[addr_index][63:32];
            2'b11: INSTRUCTION = data_blocks[addr_index][31:0];
        endcase
        // BUSYWAIT deassertion happens automatically via async hit detection logic
    end
end

// FSM
always @(posedge CLK or posedge RESET) begin
    if (RESET) begin
        state <= IDLE;
        INST_MEM_READ <= 0;
        INSTRUCTION <= 0;

        // Invalidate cache
        for (i=0; i<8; i=i+1) begin
            valids[i] <= 0;
            tags[i] <= 0;
            data_blocks[i] <= 0;
        end
    end else begin
        case(state)
        IDLE: begin
            if (BUSYWAIT && miss) begin
                // Start fetching from memory
                INST_MEM_READ <= 1;
                INST_MEM_ADDRESS <= {addr_tag[2:0], addr_index};
                state <= FETCH;
            end
        end

        FETCH: begin
            if (~INST_MEM_BUSYWAIT) begin
                INST_MEM_READ <= 0;
                // Artificial latency for writing fetched block
                #1;
                data_blocks[addr_index] <= INST_MEM_DATA;
                tags[addr_index] <= addr_tag;
                valids[addr_index] <= 1;
                state <= IDLE;
                // BUSYWAIT deassertion happens via async hit detection logic
            end
        end
        endcase
    end
end

endmodule
