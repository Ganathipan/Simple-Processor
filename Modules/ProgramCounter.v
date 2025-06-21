// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2024-06-09
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// ProgramCounter.v - Program Counter and PC Incrementer modules
// Purpose: Manages the instruction address and branching logic for the processor, including sequential and branch/jump address calculation.
// -----------------------------------------------------------------------------

// Program Counter: holds the current instruction address, updates on clock or reset.
module ProgramCounter(
    input CLK, RESET,                // Clock and reset signals
    input      [31:0] PC_IN,         // Next PC value (from PC incrementer)
    output reg [31:0] PC_OUT         // Current PC value (to instruction memory)
    );

    // On reset, set PC to 0. On clock, update PC to PC_IN.
    always @(posedge CLK or posedge RESET) begin 
        if (RESET) begin
            PC_OUT <= #1 32'b0;      // Reset PC to 0 on reset
        end
        else begin
            PC_OUT <= #1 PC_IN;      // Update PC to next value on clock
        end
    end
endmodule

// PC Incrementer: calculates next PC based on branch and jump logic.
module pcIncrementer (
    input [31:0] PC_IN,             // Current PC value
    input [7:0]  BRANCH_ADDRESS,    // Branch offset from instruction
    input [1:0]  BRANCH,            // Branch control signals
    input        JUMP, ZERO,        // Jump and zero flag
    output reg [31:0] PC_OUT        // Next PC value
    );

    reg [31:0] PC;                  // Temporary PC value
    reg [31:0] offset;              // Calculated offset for branch/jump

    always @(*) begin
        PC <= #1 PC_IN + 32'd4;     // Default: next sequential instruction (PC+4)
 
        // Calculate branch/jump offset (sign-extended, word-aligned)
        offset <= #2 PC + {{22{BRANCH_ADDRESS[7]}}, BRANCH_ADDRESS, 2'b00}; 

        // Select next PC based on control signals:
        // - JUMP: unconditional jump
        // - BRANCH == 01 and ZERO: branch if equal
        // - BRANCH == 10 and !ZERO: branch if not equal
        // - Otherwise: next sequential instruction
        PC_OUT =    JUMP ? offset : 
                    (BRANCH == 2'b01 && ZERO) ? offset : 
                    (BRANCH == 2'b10 && !ZERO) ? offset : PC;
    end
endmodule