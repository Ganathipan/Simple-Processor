module control_unit(
    input [7:0] OPCODE,
    output reg WRITE_ENABLE,
    output reg [2:0] ALUOP,
    output reg SIGN_CONTROL,
    output reg OPERAND_CONTROL,
    output reg [1:0] BRANCH_CONTROL,
    output reg JUMP_CONTROL
    );

    // ALU operation codes
    localparam OP_LOADI = 8'b00000000;
    localparam OP_MOV   = 8'b00000001;
    localparam OP_ADD   = 8'b00000010;
    localparam OP_SUB   = 8'b00000011;
    localparam OP_AND   = 8'b00000100;
    localparam OP_OR    = 8'b00000101;
    localparam OP_J     = 8'b00000110;
    localparam OP_BEQ   = 8'b00000111;
    
    localparam OP_MUL   = 8'b00001000;
    localparam OP_SHIFT = 8'b00001001;
    localparam OP_BNE   = 8'b00001010;

    always @(OPCODE) begin 
        ALUOP <= #1 (OPCODE == OP_ADD)   ? 3'b001 :
                (OPCODE == OP_SUB)   ? 3'b001 :
                (OPCODE == OP_AND)   ? 3'b010 :
                (OPCODE == OP_OR)    ? 3'b011 :
                (OPCODE == OP_MOV)   ? 3'b000 :
                (OPCODE == OP_LOADI) ? 3'b000 :
                (OPCODE == OP_MUL)   ? 3'b100 :
                (OPCODE == OP_SHIFT) ? 3'b101 :
                3'b000;

        BRANCH_CONTROL   = (OPCODE == OP_BEQ)   ? 2'b01 : 
                           (OPCODE == OP_BNE)   ? 2'b10 : 2'b00;

        JUMP_CONTROL     = (OPCODE == OP_J)     ? 1'b1 : 1'b0;

        SIGN_CONTROL     = (OPCODE == OP_SUB || OPCODE == OP_BEQ || OPCODE == OP_BNE)   ? 1'b1 : 1'b0;

        OPERAND_CONTROL  = (OPCODE == OP_LOADI || OPCODE == OP_SHIFT) ? 1'b1 : 1'b0;

        WRITE_ENABLE  = (OPCODE == OP_LOADI || OPCODE == OP_MOV || OPCODE == OP_ADD ||
                    OPCODE == OP_SUB || OPCODE == OP_AND || OPCODE == OP_OR ||
                    OPCODE == OP_MUL || OPCODE == OP_SHIFT) ? 1'b1 : 1'b0;
    end
endmodule