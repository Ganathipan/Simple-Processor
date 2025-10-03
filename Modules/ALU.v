// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// ALU.v - Arithmetic Logic Unit and related modules
// Purpose: Implements the ALU and its submodules (forward, add, and, or, mul, shifter) 
//          for the processor. Provides all arithmetic and logic operations required 
//          by the datapath with proper operation selection and flag generation.
// -----------------------------------------------------------------------------

// Main ALU Module - Central arithmetic and logic processing unit
// Selects and performs operations based on ALUOP control signal from the control unit
// Supports: forwarding, addition/subtraction, bitwise AND/OR, multiplication, shift/rotate
// Generates ZERO flag for branch instruction condition evaluation
module aluUnit(
    input [7:0] DATA1,          // 8-bit first operand (typically from register file)
    input [7:0] DATA2,          // 8-bit second operand (register or immediate value)
    input [2:0] ALUOP,          // 3-bit operation selector from control unit
    output reg [7:0] RESULT,    // 8-bit computation result
    output reg ZERO             // Zero flag for branch conditions (BEQ/BNE)
);

    // Internal wires connecting to functional unit outputs
    wire [7:0] sum, andOut, orOut, fwdOut, mulOut, shiftOut;
    wire SHIFT_E;   // Enable signal for shifter unit (active for shift operations)
    wire MUL_E;     // Enable signal for multiplier unit (active for multiply operations)

    // Generate enable signals based on ALUOP - only activate needed functional units
    assign SHIFT_E = (ALUOP == 3'b101) ? 1'b1: 1'b0;  // Enable shifter for ALUOP=101
    assign MUL_E   = (ALUOP == 3'b100) ? 1'b1: 1'b0;  // Enable multiplier for ALUOP=100

    // Instantiate functional units for each ALU operation
    // All units operate in parallel, result is selected by ALUOP in the always block
    fwdUnit     u0 (.RESULT(fwdOut)  , .DATA2(DATA2));                              // Forward unit
    addUnit     u1 (.RESULT(sum)     , .DATA1(DATA1), .DATA2(DATA2));               // Addition unit
    andUnit     u3 (.RESULT(andOut)  , .DATA1(DATA1), .DATA2(DATA2));               // Bitwise AND
    orUnit      u4 (.RESULT(orOut)   , .DATA1(DATA1), .DATA2(DATA2));               // Bitwise OR  
    mulUnit     u5 (.RESULT(mulOut)  , .DATA1(DATA1), .DATA2(DATA2), .ENABLE(MUL_E)); // Multiplier
    shifterUnit u6 (.RESULT(shiftOut), .DATA1(DATA1), .DATA2(DATA2), .ENABLE(SHIFT_E)); // Shifter
    
    // Result selection and flag generation combinational logic
    always @(*) begin
        // Multiplexer logic: select appropriate functional unit output based on ALUOP
        case (ALUOP)
            3'b000: RESULT = fwdOut;    // 000: Forward operation (MOV/LOADI instructions)
            3'b001: RESULT = sum;       // 001: Addition/Subtraction (ADD/SUB instructions)
            3'b010: RESULT = andOut;    // 010: Bitwise AND (AND instruction)
            3'b011: RESULT = orOut;     // 011: Bitwise OR (OR instruction)  
            3'b100: RESULT = mulOut;    // 100: Multiplication (MUL instruction)
            3'b101: RESULT = shiftOut;  // 101: Shift/Rotate operations (SHIFT instruction)
            default: RESULT = 8'b0;     // Default case: output zero for undefined operations
        endcase

        // Zero flag generation for branch instructions (BEQ/BNE)
        // Only considers addition result for branch condition evaluation
        ZERO = (sum == 0) ? 1'b1: 1'b0;  
    end
endmodule