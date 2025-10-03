// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// ControlUnit.v - Instruction Decoder and Control Signal Generator
// Purpose: Decodes 8-bit instruction opcodes and generates all necessary control
//          signals for the datapath including ALU operation selection, register
//          file control, memory access control, and branch/jump logic.
// -----------------------------------------------------------------------------

// Main Control Unit - Heart of the processor control logic
// Takes instruction opcode as input and generates all control signals needed
// for proper instruction execution in the datapath
module control_unit(
    input [7:0] OPCODE,             // 8-bit instruction opcode from fetched instruction
    output reg WRITE_ENABLE,        // Enable signal for register file write operation
    output reg [2:0] ALUOP,         // 3-bit ALU operation selector
    output reg SIGN_CONTROL,        // Control signal for 2's complement (SUB/branch operations)
    output reg OPERAND_CONTROL,     // Selects between register and immediate operand
    output reg [1:0] BRANCH_CONTROL,// 2-bit branch type: 00=none, 01=BEQ, 10=BNE
    output reg JUMP_CONTROL,        // Jump instruction control signal

    output reg READ_DATA_MEM,       // Data memory read enable signal for cache
    output reg WRITE_DATA_MEM       // Data memory write enable signal for cache
);

    // Instruction Set Architecture - Opcode Definitions
    // Each instruction is assigned a unique 8-bit opcode for identification
    
    // Data Movement Instructions
    localparam OP_LOADI = 8'b00000000;  // Load immediate value into register
    localparam OP_MOV   = 8'b00000001;  // Move data between registers
    
    // Arithmetic Instructions  
    localparam OP_ADD   = 8'b00000010;  // Addition operation
    localparam OP_SUB   = 8'b00000011;  // Subtraction operation
    localparam OP_MUL   = 8'b00001100;  // Multiplication operation
    
    // Logic Instructions
    localparam OP_AND   = 8'b00000100;  // Bitwise AND operation
    localparam OP_OR    = 8'b00000101;  // Bitwise OR operation
    localparam OP_SHIFT = 8'b00001101;  // Shift/Rotate operations
    
    // Control Flow Instructions
    localparam OP_J     = 8'b00000110;  // Unconditional jump
    localparam OP_BEQ   = 8'b00000111;  // Branch if equal (zero flag set)
    localparam OP_BNE   = 8'b00001110;  // Branch if not equal (zero flag clear)
    
    // Memory Access Instructions
    localparam OP_LWD   = 8'b00001000;  // Load word direct (register address)
    localparam OP_LWI   = 8'b00001001;  // Load word immediate (immediate address)
    localparam OP_SWD   = 8'b00001010;  // Store word direct (register address)
    localparam OP_SWI   = 8'b00001011;  // Store word immediate (immediate address)

    // Main control logic - generates all control signals based on instruction opcode
    // Executes whenever OPCODE input changes (combinational logic)
    always @(OPCODE) begin 
        // ALU Operation Selection - determines which ALU functional unit to use
        ALUOP <= #1 (OPCODE == OP_ADD)   ? 3'b001 :    // Addition unit
                (OPCODE == OP_SUB)   ? 3'b001 :    // Addition unit (with 2's complement)
                (OPCODE == OP_AND)   ? 3'b010 :    // Bitwise AND unit
                (OPCODE == OP_OR)    ? 3'b011 :    // Bitwise OR unit  
                (OPCODE == OP_MOV)   ? 3'b000 :    // Forward unit (pass-through)
                (OPCODE == OP_LOADI) ? 3'b000 :    // Forward unit (immediate to register)
                (OPCODE == OP_MUL)   ? 3'b100 :    // Multiplication unit
                (OPCODE == OP_SHIFT) ? 3'b101 :    // Shift/Rotate unit
                (OPCODE == OP_LWD)   ? 3'b000 :    // Forward unit (for load operations)
                (OPCODE == OP_LWI)   ? 3'b000 :    // Forward unit (for load immediate)
                (OPCODE == OP_SWD)   ? 3'b000 :    // Forward unit (for store operations)
                (OPCODE == OP_SWI)   ? 3'b000 :    // Forward unit (for store immediate)
                3'bz;                               // High impedance for undefined opcodes

        // Branch Control Logic - determines branch behavior
        BRANCH_CONTROL   = (OPCODE == OP_BEQ)   ? 2'b01 :   // Branch if equal (check zero flag)
                           (OPCODE == OP_BNE)   ? 2'b10 :   // Branch if not equal (check zero flag)
                           2'b00;                            // No branch for other instructions

        // Jump Control - unconditional program counter modification  
        JUMP_CONTROL     = (OPCODE == OP_J)     ? 1'b1 : 1'b0;

        // Sign Control - enables 2's complement for subtraction and branch comparisons
        SIGN_CONTROL     = (OPCODE == OP_SUB || OPCODE == OP_BEQ || OPCODE == OP_BNE) ? 1'b1 : 1'b0;

        // Operand Control - selects between register operand and immediate value
        OPERAND_CONTROL  = (OPCODE == OP_LOADI || OPCODE == OP_SHIFT || 
                           OPCODE == OP_LWI || OPCODE == OP_SWI) ? 1'b1 : 1'b0;

        // Register Write Enable - controls when results are written back to register file
        WRITE_ENABLE  = (OPCODE == OP_LOADI || OPCODE == OP_MOV || OPCODE == OP_ADD ||
                        OPCODE == OP_SUB || OPCODE == OP_AND || OPCODE == OP_OR ||
                        OPCODE == OP_MUL || OPCODE == OP_SHIFT  || 
                        OPCODE == OP_LWI  || OPCODE == OP_LWD) ? 1'b1 : 1'b0;

        // Memory Access Control Signals - interface with data cache
        WRITE_DATA_MEM = (OPCODE == OP_SWD || OPCODE == OP_SWI) ? 1'b1: 1'b0;  // Store operations
        READ_DATA_MEM  = (OPCODE == OP_LWD || OPCODE == OP_LWI) ? 1'b1: 1'b0;  // Load operations

    end
endmodule