// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// Description: Top-level processor and all submodules for CO224 Lab 5 Task 5. This file contains the Verilog implementation of the CPU datapath, ALU, control unit, register file, shifter, multiplier, and supporting modules. Each module is coded and commented for clarity and modularity. The design supports simulation and integration with instruction memory for full processor testing.

module fwdUnit (
    input [7:0] DATA2,
    output [7:0] RESULT);
    
    assign #1 RESULT = DATA2;
endmodule

module addUnit (
    input  [7:0] DATA1,
    input  [7:0] DATA2,
    output [7:0] RESULT);

    assign #2 RESULT = DATA1 + DATA2;
endmodule

module andUnit (
    input  [7:0] DATA1,
    input  [7:0] DATA2,
    output [7:0] RESULT);

    assign #1 RESULT = DATA1 & DATA2;
endmodule

module orUnit (
    input  [7:0] DATA1,
    input  [7:0] DATA2,
    output [7:0] RESULT);

    assign #1 RESULT = DATA1 | DATA2;
endmodule

module mulUnit (
    input  signed [7:0] DATA1,      // Multiplicand
    input  signed [7:0] DATA2,      // Multiplier
    input ENABLE,
    output reg signed [7:0] RESULT // Final 16-bit signed product
    );

    integer i;
    reg [15:0] temp1, temp2;

    always @(*) begin
        temp1 = 16'b0;
        temp2 = {8'b0, DATA1};

        for (i = 0; i < 8; i = i + 1) begin
            if (DATA2[i]) temp1 = temp1 + temp2;
            temp2 = {temp2, 1'b0};
        end

        RESULT = ENABLE ? temp1[7:0] : 8'b0; 
    end
endmodule

module shifterUnit (    
    input  [7:0] DATA1,     // 8-bit input DATA1
    input  [7:0] DATA2,     // 8-bit input DATA2
    input  ENABLE,
    output reg [7:0] RESULT // 8-bit output RESULT
    );

    integer i;
    reg sign;

    always @(*) begin
        if (ENABLE) begin
        RESULT = DATA1;
        sign = DATA1[7];
        for (i = 0; i < DATA2[3:0]; i = i + 1) begin
            case (DATA2[5:4])
                2'b00: RESULT = {RESULT[6:0], 1'b0};          // Logical shift left (sll)
                2'b01: RESULT = {1'b0, RESULT[7:1]};          // Logical shift right (srl)
                2'b10: RESULT = {sign, RESULT[7:1]};          // Arithmetic shift right (sra)
                2'b11: RESULT = {RESULT[0], RESULT[7:1]};     // Rotate right (ror)
            endcase
        end
        //#4; // Delay for shifting
        end 
        else begin
            RESULT = 8'B0;
        end
    end
endmodule

module aluUnit(
    input [7:0] DATA1,        // 8-bit input DATA1
    input [7:0] DATA2,        // 8-bit input DATA2
    input [2:0] ALUOP,     // 3-bit selector to choose operation
    output reg [7:0] RESULT,   // 8-bit output RESULT
    output reg ZERO
    );

    wire [7:0] sum, andOut, orOut, fwdOut, mulOut, shiftOut;
    wire SHIFT_E;

    assign SHIFT_E = (ALUOP == 3'b101) ? 1'b1: 1'b0;
    assign MUL_E   = (ALUOP == 3'b100) ? 1'b1: 1'b0;

    fwdUnit     u0 (.RESULT(fwdOut)  , .DATA2(DATA2));
    addUnit     u1 (.RESULT(sum)     , .DATA1(DATA1), .DATA2(DATA2));
    andUnit     u3 (.RESULT(andOut)  , .DATA1(DATA1), .DATA2(DATA2));
    orUnit      u4 (.RESULT(orOut)   , .DATA1(DATA1), .DATA2(DATA2));
    mulUnit     u5 (.RESULT(mulOut)  , .DATA1(DATA1), .DATA2(DATA2), .ENABLE(MUL_E));
    shifterUnit u6 (.RESULT(shiftOut), .DATA1(DATA1), .DATA2(DATA2), .ENABLE(SHIFT_E));
    
    always @(*) begin
        case (ALUOP)
            3'b000: RESULT = fwdOut;    
            3'b001: RESULT = sum;      
            3'b010: RESULT = andOut;  
            3'b011: RESULT = orOut;
            3'b100: RESULT = mulOut;
            3'b101: RESULT = shiftOut;                
            default: RESULT = 8'b0; 
        endcase

        // Sets the ZERO flag if the result is zero
        ZERO = (sum == 0) ? 1'b1: 1'b0;  
    end
endmodule

module reg_file(
    input [7:0] INDATA,             
    input [2:0] INADDRESS,          
    input [2:0] OUT1ADDRESS,        
    input [2:0] OUT2ADDRESS,        
    output reg [7:0] OUT1DATA,      
    output reg [7:0] OUT2DATA,      
    input CLK,                      
    input RESET,                    
    input  WRITE                    
    );

    reg [7:0] reg_array [0:7]; 

    always @(*) begin
        OUT1DATA <= #2 reg_array[OUT1ADDRESS];  
        OUT2DATA <= #2 reg_array[OUT2ADDRESS];  
    end

    always @(posedge CLK) begin
        if(WRITE == 1'b1  &&  RESET == 1'b0) begin 
            reg_array[INADDRESS] <= #1 INDATA;
        end
    end

    integer counter;             
    always @(posedge CLK) begin
        if(RESET == 1'b1) begin
            for(counter = 0; counter < 8; counter = counter + 1) begin
                reg_array[counter] <= #1 8'b00000000;
            end
        end
    end
endmodule

module control_unit(
    input [7:0] OPCODE,
    output reg WRITE_ENABLE,
    output reg [2:0] ALUOP,
    output reg SIGN_CONTROL,
    output reg OPERAND_CONTROL,
    output reg [1:0] BRANCH_CONTROL,
    output reg JUMP_CONTROL,

    output reg READ_DATA_MEM, WRITE_DATA_MEM                  //<--------------
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
    
    localparam OP_MUL   = 8'b00001100;
    localparam OP_SHIFT = 8'b00001101;
    localparam OP_BNE   = 8'b00001110;

    localparam OP_LWD   = 8'b00001000;                      //<--------------
    localparam OP_LWI   = 8'b00001001;
    localparam OP_SWD   = 8'b00001010;
    localparam OP_SWI   = 8'b00001011;                      //<--------------

    always @(OPCODE) begin 
        ALUOP <= #1 (OPCODE == OP_ADD)   ? 3'b001 :
                (OPCODE == OP_SUB)   ? 3'b001 :
                (OPCODE == OP_AND)   ? 3'b010 :
                (OPCODE == OP_OR)    ? 3'b011 :
                (OPCODE == OP_MOV)   ? 3'b000 :
                (OPCODE == OP_LOADI) ? 3'b000 :
                (OPCODE == OP_MUL)   ? 3'b100 :
                (OPCODE == OP_SHIFT) ? 3'b101 :
                (OPCODE == OP_LWD)   ? 3'b000 :             //<--------------
                (OPCODE == OP_LWI)   ? 3'b000 :
                (OPCODE == OP_SWD)   ? 3'b000 :
                (OPCODE == OP_SWI)   ? 3'b000 :             //<--------------
                3'bz;

        BRANCH_CONTROL   = (OPCODE == OP_BEQ)   ? 2'b01 : 
                           (OPCODE == OP_BNE)   ? 2'b10 : 2'b00;

        JUMP_CONTROL     = (OPCODE == OP_J)     ? 1'b1 : 1'b0;

        SIGN_CONTROL     = (OPCODE == OP_SUB || OPCODE == OP_BEQ || OPCODE == OP_BNE)   ? 1'b1 : 1'b0;

        OPERAND_CONTROL  = (OPCODE == OP_LOADI || OPCODE == OP_SHIFT || OPCODE == OP_LWI || OPCODE == OP_SWI) ? 1'b1 : 1'b0;

        WRITE_ENABLE  = (OPCODE == OP_LOADI || OPCODE == OP_MOV || OPCODE == OP_ADD ||
                        OPCODE == OP_SUB || OPCODE == OP_AND || OPCODE == OP_OR ||
                        OPCODE == OP_MUL || OPCODE == OP_SHIFT  || OPCODE == OP_SWI  || OPCODE == OP_SWD) ? 1'b1 : 1'b0;

        WRITE_DATA_MEM = (OPCODE == OP_LWD || OPCODE == OP_LWI) ? 1'b1: 1'b0;                                                 //<-----------------
        READ_DATA_MEM = (OPCODE == OP_SWD || OPCODE == OP_SWI) ? 1'b1: 1'b0;                                                 //<-----------------

    end
endmodule

module ProgramCounter(
    input CLK, RESET,
    input      [31:0] PC_IN,
    output reg [31:0] PC_OUT
    );

    always @(posedge CLK or posedge RESET) begin 
        if (RESET) begin
            PC_OUT <= #1 32'b0;
        end
        else begin
            PC_OUT <= #1 PC_IN;
        end
    end
endmodule

module pcIncrementer (
    input [31:0] PC_IN,
    input [7:0]  BRANCH_ADDRESS,
    input [1:0]  BRANCH, 
    input        JUMP, ZERO,
    input       BUSYWAIT,
    output reg [31:0] PC_OUT
    );

    reg [31:0] PC;
    reg [31:0] offset;

    always @(*) begin
        PC <= #1 PC_IN + 32'd4;
 
        offset <= #2 PC + {{22{BRANCH_ADDRESS[7]}}, BRANCH_ADDRESS, 2'b00}; 

        PC_OUT =    BUSYWAIT ? PC_IN : 
                    JUMP ? offset : 
                    (BRANCH == 2'b01 && ZERO) ? offset : 
                    (BRANCH == 2'b10 && !ZERO) ? offset : PC;
    end
endmodule

module CPU(
    input [31:0] INSTRUCTION,
    input CLK, RESET, 
    output wire [31:0] PC_OUT
    );

    wire [7:0] OPERAND1, OPERAND2, ALURESULT;
    wire [2:0] ALUOP;
    wire REG_WRITE_ENABLE;
    wire SIGN_CONTROL, OPERAND_CONTROL;

    wire [1:0] BRANCH_CONTROL;
    wire JUMP_CONTROL;
    wire ZERO_FLAG;        
    wire [31:0] PC_IN;

    wire READ_DATA_MEM, WRITE_DATA_MEM, BUSYWAIT;
    wire [7:0] READ_MEM_OUT;
    reg [7:0] REG_INDATA;

    ProgramCounter u_pc (
        .CLK(CLK),
        .RESET(RESET),
        .PC_IN(PC_IN),
        .PC_OUT(PC_OUT)
    );

    pcIncrementer u_pcIn (
        .PC_IN(PC_OUT),
        .BRANCH_ADDRESS(INSTRUCTION[15:8]),
        .BRANCH(BRANCH_CONTROL), 
        .JUMP(JUMP_CONTROL), 
        .ZERO(ZERO_FLAG),
        .BUSYWAIT(BUSYWAIT),
        .PC_OUT(PC_IN)
    );
    
    control_unit u_control (
        .OPCODE (INSTRUCTION[7:0]),
        .WRITE_ENABLE(REG_WRITE_ENABLE),
        .ALUOP(ALUOP),
        .SIGN_CONTROL(SIGN_CONTROL),
        .OPERAND_CONTROL(OPERAND_CONTROL),
        .BRANCH_CONTROL(BRANCH_CONTROL),
        .JUMP_CONTROL(JUMP_CONTROL),
        .READ_DATA_MEM(READ_DATA_MEM),
        .WRITE_DATA_MEM(WRITE_DATA_MEM)
    );

    reg_file u_regfile (
        .INDATA(REG_INDATA),
        .INADDRESS(INSTRUCTION[10:8]),
        .OUT1ADDRESS(INSTRUCTION[18:16]),
        .OUT2ADDRESS(INSTRUCTION[26:24]),
        .OUT1DATA(OPERAND1),
        .OUT2DATA(OPERAND2),
        .WRITE(REG_WRITE_ENABLE),
        .CLK(CLK),
        .RESET(RESET)
    ); 

    reg [7:0] ALU_IN_DATA1, ALU_IN_DATA2;

    always @(*) begin
        ALU_IN_DATA1 = OPERAND1;
        if (OPERAND_CONTROL) begin
            ALU_IN_DATA2 = INSTRUCTION[31:24];
        end
        else begin
            if (SIGN_CONTROL) begin
                ALU_IN_DATA2 <= #2 (~OPERAND2 + 8'b1);
            end
            else begin
                ALU_IN_DATA2 = OPERAND2;
            end
        end
    end    

    always @(*) begin
        REG_INDATA = READ_DATA_MEM ? READ_MEM_OUT : ALURESULT;
    end

    aluUnit u_alu (
        .DATA1(ALU_IN_DATA1),
        .DATA2(ALU_IN_DATA2),
        .ALUOP(ALUOP),
        .RESULT(ALURESULT),
        .ZERO(ZERO_FLAG)
    );

    data_memory u_data_mem(
        .clock(CLK),
        .reset(RESET),
        .read(READ_DATA_MEM),
        .write(WRITE_DATA_MEM),
        .address(ALURESULT),
        .writedata(OPERAND1),
        .readdata(READ_MEM_OUT),
        .busywait(BUSYWAIT)
    );
endmodule