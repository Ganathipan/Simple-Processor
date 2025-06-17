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
    wire ZERO_FLAG;              // to control the gates for beq instruction
    wire [31:0] PC_IN;

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
        .PC_OUT(PC_IN)
    );
    
    control_unit u_control (
        .OPCODE (INSTRUCTION[7:0]),
        .WRITE_ENABLE(REG_WRITE_ENABLE),
        .ALUOP(ALUOP),
        .SIGN_CONTROL(SIGN_CONTROL),
        .OPERAND_CONTROL(OPERAND_CONTROL),
        .BRANCH_CONTROL(BRANCH_CONTROL),
        .JUMP_CONTROL(JUMP_CONTROL)
    );

    reg_file u_regfile (
        .IN(ALURESULT),
        .INADDRESS(INSTRUCTION[10:8]),
        .OUT1ADDRESS(INSTRUCTION[18:16]),
        .OUT2ADDRESS(INSTRUCTION[26:24]),
        .OUT1(OPERAND1),
        .OUT2(OPERAND2),
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
            if (signControl) begin
                ALU_IN_DATA2 <= #2 (~OPERAND2 + 8'b1);
            end
            else begin
                ALU_IN_DATA2 = OPERAND2;
            end
        end
    end    

    aluUnit u_alu (
        .DATA1(ALU_IN_DATA1),
        .DATA2(ALU_IN_DATA2),
        .SELECT(ALUOP),
        .RESULT(ALURESULT),
        .ZERO(ZERO_FLAG)
    );
endmodule
