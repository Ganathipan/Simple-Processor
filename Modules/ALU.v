// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2024-06-09
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// ALU.v - Arithmetic Logic Unit and related modules
// Purpose: Implements the ALU and its submodules (forward, add, and, or, mul, shifter) for the processor. Provides all arithmetic and logic operations required by the datapath.
// -----------------------------------------------------------------------------

// ALU.v - Arithmetic Logic Unit and related modules
// This file contains the implementation of the ALU and its submodules for the processor.

// Forwarding unit: simply forwards DATA2 to RESULT after 1 time unit delay.
module fwdUnit (
    input [7:0] DATA2,           // Input data to be forwarded
    output [7:0] RESULT          // Output data (same as DATA2)
    );
    // Forward DATA2 to RESULT after 1 time unit. Used for MOV/LOADI operations.
    assign #1 RESULT = DATA2;
endmodule

// Addition unit: adds DATA1 and DATA2, outputs RESULT after 2 time units.
module addUnit (
    input  [7:0] DATA1,          // First operand
    input  [7:0] DATA2,          // Second operand
    output [7:0] RESULT          // Output: sum of DATA1 and DATA2
    );
    // Perform addition with a delay of 2 time units to simulate hardware latency.
    assign #2 RESULT = DATA1 + DATA2;
endmodule

// AND unit: bitwise AND of DATA1 and DATA2, outputs RESULT after 1 time unit.
module andUnit (
    input  [7:0] DATA1,          // First operand
    input  [7:0] DATA2,          // Second operand
    output [7:0] RESULT          // Output: bitwise AND
    );
    // Perform bitwise AND with a delay of 1 time unit.
    assign #1 RESULT = DATA1 & DATA2;
endmodule

// OR unit: bitwise OR of DATA1 and DATA2, outputs RESULT after 1 time unit.
module orUnit (
    input  [7:0] DATA1,          // First operand
    input  [7:0] DATA2,          // Second operand
    output [7:0] RESULT          // Output: bitwise OR
    );
    // Perform bitwise OR with a delay of 1 time unit.
    assign #1 RESULT = DATA1 | DATA2;
endmodule

// Multiplier unit: multiplies DATA1 and DATA2 using shift-and-add algorithm.
// ENABLE controls whether multiplication is performed.
module mulUnit (
    input  signed [7:0] DATA1,      // Multiplicand (signed)
    input  signed [7:0] DATA2,      // Multiplier (signed)
    input ENABLE,                   // Enable signal for multiplication
    output reg signed [7:0] RESULT  // 8-bit signed product (lower byte)
    );
    integer i;                      // Loop variable for shift-and-add
    reg [15:0] temp1, temp2;        // Temporary registers for calculation

    always @(*) begin
        temp1 = 16'b0;              // Accumulator for result, initialized to 0
        temp2 = {8'b0, DATA1};      // Place DATA1 in lower 8 bits for shifting

        // Shift-and-add multiplication: for each bit in DATA2, add shifted DATA1 if bit is set
        for (i = 0; i < 8; i = i + 1) begin
            if (DATA2[i]) temp1 = temp1 + temp2; // Add shifted multiplicand if multiplier bit is 1
            temp2 = {temp2, 1'b0};              // Shift multiplicand left by 1
        end

        // Output lower 8 bits of result if ENABLE is high, else output 0
        RESULT = ENABLE ? temp1[7:0] : 8'b0;
    end
endmodule

// Shifter unit: performs logical/arithmetic shifts and rotate right.
// DATA2[5:4] selects shift type, DATA2[3:0] is shift amount.
module shifterUnit (
    input  [7:0] DATA1,     // 8-bit input DATA1 to be shifted
    input  [7:0] DATA2,     // 8-bit input: [5:4]=shift type, [3:0]=amount
    input  ENABLE,          // Enable signal for shifting
    output reg [7:0] RESULT // 8-bit output RESULT
    );
    integer i;              // Loop variable for shift amount
    reg sign;               // Sign bit for arithmetic shift

    always @(*) begin
        if (ENABLE) begin
            RESULT = DATA1; // Start with input value
            sign = DATA1[7]; // Save sign bit for arithmetic shift right
            // Perform the shift/rotate operation for the specified amount
            for (i = 0; i < DATA2[3:0]; i = i + 1) begin
                case (DATA2[5:4])
                    2'b00: RESULT = {RESULT[6:0], 1'b0};          // Logical shift left (sll)
                    2'b01: RESULT = {1'b0, RESULT[7:1]};          // Logical shift right (srl)
                    2'b10: RESULT = {sign, RESULT[7:1]};          // Arithmetic shift right (sra)
                    2'b11: RESULT = {RESULT[0], RESULT[7:1]};     // Rotate right (ror)
                endcase
            end
        end 
        else begin
            RESULT = 8'B0; // Output zero if not enabled
        end
    end
endmodule

// ALU unit: selects and performs operation based on ALUOP.
// Supports forwarding, add, and, or, mul, shift.
module aluUnit(
    input [7:0] DATA1,        // 8-bit input DATA1 (first operand)
    input [7:0] DATA2,        // 8-bit input DATA2 (second operand or immediate)
    input [2:0] ALUOP,        // 3-bit selector to choose operation
    output reg [7:0] RESULT,  // 8-bit output RESULT
    output reg ZERO           // Zero flag for branch instructions
    );

    // Internal wires for each operation result
    wire [7:0] sum, andOut, orOut, fwdOut, mulOut, shiftOut;
    wire SHIFT_E; // Enable for shifter
    wire MUL_E;   // Enable for multiplier

    // Enable shifter if ALUOP is 101 (shift), multiplier if ALUOP is 100 (mul)
    assign SHIFT_E = (ALUOP == 3'b101) ? 1'b1: 1'b0;
    assign MUL_E   = (ALUOP == 3'b100) ? 1'b1: 1'b0;

    // Instantiate submodules for each operation
    fwdUnit     u0 (.RESULT(fwdOut)  , .DATA2(DATA2));
    addUnit     u1 (.RESULT(sum)     , .DATA1(DATA1), .DATA2(DATA2));
    andUnit     u3 (.RESULT(andOut)  , .DATA1(DATA1), .DATA2(DATA2));
    orUnit      u4 (.RESULT(orOut)   , .DATA1(DATA1), .DATA2(DATA2));
    mulUnit     u5 (.RESULT(mulOut)  , .DATA1(DATA1), .DATA2(DATA2), .ENABLE(MUL_E));
    shifterUnit u6 (.RESULT(shiftOut), .DATA1(DATA1), .DATA2(DATA2), .ENABLE(SHIFT_E));
    
    always @(*) begin
        // Select operation based on ALUOP
        case (ALUOP)
            3'b000: RESULT = fwdOut;    // Forward (MOV/LOADI)
            3'b001: RESULT = sum;      // Add/Sub
            3'b010: RESULT = andOut;   // AND
            3'b011: RESULT = orOut;    // OR
            3'b100: RESULT = mulOut;   // Multiply
            3'b101: RESULT = shiftOut; // Shift/Rotate
            default: RESULT = 8'b0;    // Default to zero
        endcase

        // Sets the ZERO flag if the result of addition/subtraction is zero (for branch instructions)
        ZERO = (sum == 0) ? 1'b1: 1'b0;  
    end
endmodule