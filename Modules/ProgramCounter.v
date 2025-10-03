// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// ProgramCounter.v - Program Counter and Address Management
// Purpose: Manages instruction sequencing through program counter register and
//          branch/jump address calculation. Handles sequential execution and
//          control flow changes with proper pipeline stall support.
// -----------------------------------------------------------------------------

// Program Counter Register - Stores current instruction address
// Simple clocked register that holds the address of the currently executing instruction
// Updates on each clock cycle unless stalled by cache miss (BUSYWAIT)
module ProgramCounter(
    input wire CLK,             // System clock for synchronous operation
    input wire RESET,           // Asynchronous reset signal (active high)
    input wire [31:0] PC_IN,    // Next PC value from PC incrementer
    output reg [31:0] PC_OUT,   // Current PC value (instruction address)
    input wire BUSYWAIT         // Pipeline stall signal from cache subsystem
);

    // Synchronous PC register update logic
    always @(posedge CLK or posedge RESET) begin 
        if (RESET) begin
            PC_OUT <= #1 32'b0;    // Reset PC to address 0 (start of program)
        end
        else begin
            PC_OUT <= #1 PC_IN;    // Update PC with new value (sequential or branch target)
        end
    end
endmodule

// PC Incrementer and Branch Logic - Calculates next instruction address
// Handles sequential execution (+4), branch target calculation, and jump addresses
// Implements branch condition evaluation and proper pipeline stall handling
module pcIncrementer (
    input wire CLK,                     // System clock
    input wire RESET,                   // Reset signal
    input wire [31:0] PC_IN,            // Current PC value
    input wire [7:0]  BRANCH_ADDRESS,   // 8-bit branch offset from instruction
    input wire [1:0]  BRANCH,           // Branch type: 00=none, 01=BEQ, 10=BNE  
    input wire JUMP,                    // Jump instruction signal
    input wire ZERO,                    // Zero flag from ALU for branch conditions
    input wire BUSYWAIT,                // Cache busy signal for pipeline stalls
    output reg [31:0] PC_OUT            // Next PC value to program counter
);

    reg [31:0] PC;              // Next sequential PC (current PC + 4)
    reg [31:0] offset;          // Branch/jump target address
    reg [31:0] PC_PREV;         // Previous PC value for stall handling

    // Reset logic - initialize all PC-related registers
    always @(RESET) begin
        PC = 32'b0;         // Sequential PC starts at 0
        PC_OUT = 32'b0;     // Output PC starts at 0  
        PC_PREV = 32'b0;    // Previous PC starts at 0
    end

    // PC calculation combinational logic
    always @(*) begin
        if (BUSYWAIT) begin
            // Pipeline stall: hold previous PC value during cache miss
            PC_OUT = PC_PREV;
        end
        else begin
            PC_PREV = PC_IN;    // Store current PC for potential stall
            
            // Calculate sequential PC (word-aligned: +4 bytes)
            PC <= #1 PC_IN + 32'd4;

            // Calculate branch/jump target with sign extension
            // Branch offset is sign-extended from 8 bits to 32 bits and word-aligned
            offset <= #2 PC + {{22{BRANCH_ADDRESS[7]}}, BRANCH_ADDRESS, 2'b00}; 

            // PC selection logic based on instruction type and conditions
            PC_OUT =    JUMP ? offset :                         // Unconditional jump
                        (BRANCH == 2'b01 && ZERO) ? offset :   // BEQ: branch if zero flag set
                        (BRANCH == 2'b10 && !ZERO) ? offset :  // BNE: branch if zero flag clear
                        PC;                                     // Sequential execution
        end
    end
endmodule