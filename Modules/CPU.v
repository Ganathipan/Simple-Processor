// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// CPU.v - Top-level CPU module
// Purpose: Integrates all processor components (PC, control unit, register file, ALU, and datapath logic) to form a complete CPU capable of executing instructions.
// -----------------------------------------------------------------------------

// CPU.v - Top-level CPU module
// This module integrates all processor components: PC, control unit, register file, ALU, and datapath logic.

module CPU(
    input CLK, RESET, 

    // Data Memory interface
    output wire READ_DATA_MEM2CAC,
    output wire WRITE_DATA_MEM2CAC,
    output wire [5:0] MEM_ADDRESS_MEM2CAC,
    output wire [31:0] OUTDATA_MEM2CAC,
    input [31:0] INDATA_MEM2CAC,
    input BUSYWAIT_MEM2CAC,

    // Instruction Memory interface
    output wire INST_MEM_READ,
    output wire [5:0] INST_MEM_ADDRESS,
    input [127:0] INST_MEM_DATA,
    input INST_MEM_BUSYWAIT
    );

    // Instruction from cache
    wire [31:0] INSTRUCTION;
    wire BUSYWAIT_INST_CACHE;

    // General Control Signals
    wire [7:0] OPERAND1, OPERAND2, ALURESULT;
    wire [2:0] ALUOP;
    wire REG_WRITE_ENABLE;
    wire SIGN_CONTROL, OPERAND_CONTROL;

    wire [1:0] BRANCH_CONTROL;
    wire JUMP_CONTROL;
    wire ZERO_FLAG;
    wire [31:0] PC_IN;
    wire [31:0] PC_OUT;
    wire BUSYWAIT;

    wire READ_DATA_MEM, WRITE_DATA_MEM;
    wire BUSYWAIT_DATA_CACHE;
    wire [7:0] READ_MEM_OUT;
    reg [7:0] REG_INDATA;

    assign BUSYWAIT = BUSYWAIT_MEM2CAC || BUSYWAIT_INST_CACHE;

    ProgramCounter u_pc (
        .CLK(CLK),
        .RESET(RESET),
        .PC_IN(PC_IN),
        .PC_OUT(PC_OUT),
        .BUSYWAIT(BUSYWAIT)
    );

    pcIncrementer u_pcIn (
        .CLK(CLK),
        .RESET(RESET),
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
        end else begin
            if (SIGN_CONTROL)
                ALU_IN_DATA2 = ~OPERAND2 + 1;
            else
                ALU_IN_DATA2 = OPERAND2;
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

    data_cache u_data_cache(
        .clk(CLK),
        .reset(RESET),
        .read(READ_DATA_MEM),
        .write(WRITE_DATA_MEM),
        .address(ALURESULT),
        .writedata(OPERAND1),
        .readdata(READ_MEM_OUT),
        .busywait(BUSYWAIT_DATA_CACHE),
        .mem_read(READ_DATA_MEM2CAC),
        .mem_write(WRITE_DATA_MEM2CAC),
        .mem_address(MEM_ADDRESS_MEM2CAC),
        .mem_writedata(OUTDATA_MEM2CAC),
        .mem_readdata(INDATA_MEM2CAC),
        .mem_busywait(BUSYWAIT_MEM2CAC)
    );

    inst_cache u_inst_cache(
    .clock(CLK),
    .reset(RESET),
    .address(PC_OUT),
    .readdata(INSTRUCTION),
    .busywait(BUSYWAIT_INST_CACHE),
    .mem_read(INST_MEM_READ),
    .mem_address(INST_MEM_ADDRESS),
    .mem_readdata(INST_MEM_DATA),
    .mem_busywait(INST_MEM_BUSYWAIT)
);

endmodule