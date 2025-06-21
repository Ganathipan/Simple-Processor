// ControlUnit.v - Control Unit for the processor
// This module decodes the instruction opcode and generates control signals for the datapath.

module control_unit(
    input [7:0] OPCODE,                // 8-bit instruction opcode from instruction memory
    output reg WRITE_ENABLE,           // Enables writing to the register file
    output reg [2:0] ALUOP,            // Selects which ALU operation to perform
    output reg SIGN_CONTROL,           // Selects signed/unsigned or subtraction
    output reg OPERAND_CONTROL,        // Selects immediate or register operand
    output reg [1:0] BRANCH_CONTROL,   // Controls branch logic (beq, bne)
    output reg JUMP_CONTROL            // Controls jump logic
    );

    // Define opcodes for each instruction (must match assembler and datapath)
    localparam OP_LOADI = 8'b00000000; // Load immediate
    localparam OP_MOV   = 8'b00000001; // Move register
    localparam OP_ADD   = 8'b00000010; // Add
    localparam OP_SUB   = 8'b00000011; // Subtract
    localparam OP_AND   = 8'b00000100; // Bitwise AND
    localparam OP_OR    = 8'b00000101; // Bitwise OR
    localparam OP_J     = 8'b00000110; // Unconditional jump
    localparam OP_BEQ   = 8'b00000111; // Branch if equal
    localparam OP_MUL   = 8'b00001000; // Multiply
    localparam OP_SHIFT = 8'b00001001; // Shift/rotate
    localparam OP_BNE   = 8'b00001010; // Branch if not equal

    // Combinational logic to decode opcode and set control signals for datapath
    always @(OPCODE) begin 
        // ALUOP selects which ALU operation to perform (see ALU.v)
        ALUOP <= #1 (OPCODE == OP_ADD)   ? 3'b001 :
                (OPCODE == OP_SUB)   ? 3'b001 :
                (OPCODE == OP_AND)   ? 3'b010 :
                (OPCODE == OP_OR)    ? 3'b011 :
                (OPCODE == OP_MOV)   ? 3'b000 :
                (OPCODE == OP_LOADI) ? 3'b000 :
                (OPCODE == OP_MUL)   ? 3'b100 :
                (OPCODE == OP_SHIFT) ? 3'b101 :
                3'b000;

        // BRANCH_CONTROL: 01 for beq, 10 for bne, 00 otherwise
        BRANCH_CONTROL   = (OPCODE == OP_BEQ)   ? 2'b01 : 
                           (OPCODE == OP_BNE)   ? 2'b10 : 2'b00;

        // JUMP_CONTROL: 1 for jump, 0 otherwise
        JUMP_CONTROL     = (OPCODE == OP_J)     ? 1'b1 : 1'b0;

        // SIGN_CONTROL: 1 for sub, beq, bne (for subtraction/negation), 0 otherwise
        SIGN_CONTROL     = (OPCODE == OP_SUB || OPCODE == OP_BEQ || OPCODE == OP_BNE)   ? 1'b1 : 1'b0;

        // OPERAND_CONTROL: 1 for loadi, shift (immediate), 0 otherwise
        OPERAND_CONTROL  = (OPCODE == OP_LOADI || OPCODE == OP_SHIFT) ? 1'b1 : 1'b0;

        // WRITE_ENABLE: enables register write for arithmetic/logical instructions
        WRITE_ENABLE  = (OPCODE == OP_LOADI || OPCODE == OP_MOV || OPCODE == OP_ADD ||
                    OPCODE == OP_SUB || OPCODE == OP_AND || OPCODE == OP_OR ||
                    OPCODE == OP_MUL || OPCODE == OP_SHIFT) ? 1'b1 : 1'b0;
    end
endmodule