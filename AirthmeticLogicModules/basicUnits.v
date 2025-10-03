// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// basicUnits.v - Fundamental ALU Operation Units
// Purpose: Contains basic arithmetic and logic operation modules that serve as 
//          building blocks for the ALU. Each unit implements a specific operation
//          with realistic propagation delays for timing simulation.
// -----------------------------------------------------------------------------

// Forward Unit - Simple pass-through operation
// Used for MOV and LOADI instructions where DATA2 is directly forwarded to output
module fwdUnit (
    input [7:0] DATA2,      // 8-bit input data to be forwarded
    output [7:0] RESULT     // 8-bit output (same as DATA2)
);
    
    // Forward DATA2 to RESULT with 1ns propagation delay
    assign #1 RESULT = DATA2;
endmodule

// Addition Unit - Performs 8-bit arithmetic addition
// Used for ADD and SUB instructions (SUB uses 2's complement of DATA2)
// Also used for address calculation in memory operations
module addUnit (
    input  [7:0] DATA1,     // 8-bit first operand (typically from register)
    input  [7:0] DATA2,     // 8-bit second operand (register or immediate)
    output [7:0] RESULT     // 8-bit sum result (DATA1 + DATA2)
);

    // Perform addition with 2ns propagation delay (realistic for 8-bit adder)
    assign #2 RESULT = DATA1 + DATA2;
endmodule

// Bitwise AND Unit - Performs logical AND operation
// Used for AND instruction and bit masking operations
module andUnit (
    input  [7:0] DATA1,     // 8-bit first operand
    input  [7:0] DATA2,     // 8-bit second operand  
    output [7:0] RESULT     // 8-bit bitwise AND result
);

    // Perform bitwise AND with 1ns propagation delay
    assign #1 RESULT = DATA1 & DATA2;
endmodule

// Bitwise OR Unit - Performs logical OR operation  
// Used for OR instruction and bit setting operations
module orUnit (
    input  [7:0] DATA1,     // 8-bit first operand
    input  [7:0] DATA2,     // 8-bit second operand
    output [7:0] RESULT     // 8-bit bitwise OR result
);

    // Perform bitwise OR with 1ns propagation delay
    assign #1 RESULT = DATA1 | DATA2;
endmodule

// Multiplication Unit - Performs 8-bit signed multiplication
// Uses shift-and-add algorithm for implementation, returns lower 8 bits only
// Enabled only when MUL instruction is executed (controlled by ENABLE signal)
module mulUnit (
    input  signed [7:0] DATA1,      // 8-bit signed multiplicand
    input  signed [7:0] DATA2,      // 8-bit signed multiplier  
    input ENABLE,                   // Enable signal from ALU control
    output reg signed [7:0] RESULT  // 8-bit result (lower bits of 16-bit product)
);

    integer i;                      // Loop counter for shift-and-add algorithm
    reg [15:0] temp1, temp2;       // Temporary registers for computation

    // Combinational multiplication using shift-and-add algorithm
    always @(*) begin
        temp1 = 16'b0;              // Initialize accumulator
        temp2 = {8'b0, DATA1};      // Zero-extend multiplicand to 16 bits

        // Shift-and-add multiplication algorithm
        for (i = 0; i < 8; i = i + 1) begin
            if (DATA2[i]) temp1 = temp1 + temp2;  // Add if multiplier bit is 1
            temp2 = {temp2, 1'b0};                 // Shift multiplicand left
        end

        // Output lower 8 bits only, or zero if disabled
        RESULT = ENABLE ? temp1[7:0] : 8'b0; 
    end
endmodule

// Shifter Unit - Universal shift and rotate operations
// Supports logical left/right shift, arithmetic right shift, and rotate right
// Shift amount and type are encoded in DATA2, data to shift is in DATA1
module shifterUnit (    
    input  [7:0] DATA1,     // 8-bit data to be shifted/rotated
    input  [7:0] DATA2,     // Control word: [7:6]=unused, [5:4]=shift_type, [3:0]=shift_amount
    input  ENABLE,          // Enable signal from ALU control
    output reg [7:0] RESULT // 8-bit shifted/rotated result
);

    integer i;              // Loop counter for iterative shifting
    reg sign;              // Sign bit for arithmetic right shift

    // Combinational shift/rotate logic
    always @(*) begin
        if (ENABLE) begin
            RESULT = DATA1;         // Initialize with input data
            sign = DATA1[7];        // Capture sign bit for arithmetic operations
            
            // Perform shift/rotate operation for specified amount (DATA2[3:0])
            for (i = 0; i < DATA2[3:0]; i = i + 1) begin
                case (DATA2[5:4])   // Decode shift type from DATA2[5:4]
                    2'b00: RESULT = {RESULT[6:0], 1'b0};          // Logical shift left (SLL)
                    2'b01: RESULT = {1'b0, RESULT[7:1]};          // Logical shift right (SRL)  
                    2'b10: RESULT = {sign, RESULT[7:1]};          // Arithmetic shift right (SRA)
                    2'b11: RESULT = {RESULT[0], RESULT[7:1]};     // Rotate right (ROR)
                endcase
            end
        end 
        else begin
            RESULT = 8'b0;          // Output zero when disabled
        end
    end
endmodule