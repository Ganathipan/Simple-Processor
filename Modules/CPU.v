// CPU.v - Top-level CPU module
// This module integrates all processor components: PC, control unit, register file, ALU, and datapath logic.

module CPU(
    input [31:0] INSTRUCTION,      // 32-bit instruction from instruction memory
    input CLK, RESET,              // Clock and reset signals
    output wire [31:0] PC_OUT      // Program counter output (current instruction address)
    );

    // Internal wires for datapath (connect modules)
    wire [7:0] OPERAND1, OPERAND2, ALURESULT; // Register values and ALU result
    wire [2:0] ALUOP;                        // ALU operation selector
    wire REG_WRITE_ENABLE;                    // Register write enable
    wire SIGN_CONTROL, OPERAND_CONTROL;       // ALU input controls
    wire [1:0] BRANCH_CONTROL;                // Branch control signals
    wire JUMP_CONTROL;                        // Jump control signal
    wire ZERO_FLAG;                           // Zero flag for branch instructions
    wire [31:0] PC_IN;                        // Next PC value

    // Program Counter: holds the current instruction address
    ProgramCounter u_pc (
        .CLK(CLK),
        .RESET(RESET),
        .PC_IN(PC_IN),
        .PC_OUT(PC_OUT)
    );

    // PC Incrementer: calculates next PC based on branch/jump logic
    pcIncrementer u_pcIn (
        .PC_IN(PC_OUT),
        .BRANCH_ADDRESS(INSTRUCTION[15:8]), // Branch offset from instruction
        .BRANCH(BRANCH_CONTROL), 
        .JUMP(JUMP_CONTROL), 
        .ZERO(ZERO_FLAG),
        .PC_OUT(PC_IN)
    );
    
    // Control Unit: decodes instruction and generates control signals
    control_unit u_control (
        .OPCODE (INSTRUCTION[7:0]),
        .WRITE_ENABLE(REG_WRITE_ENABLE),
        .ALUOP(ALUOP),
        .SIGN_CONTROL(SIGN_CONTROL),
        .OPERAND_CONTROL(OPERAND_CONTROL),
        .BRANCH_CONTROL(BRANCH_CONTROL),
        .JUMP_CONTROL(JUMP_CONTROL)
    );

    // Register File: stores general-purpose registers
    reg_file u_regfile (
        .INDATA(ALURESULT),
        .INADDRESS(INSTRUCTION[10:8]),
        .OUT1ADDRESS(INSTRUCTION[18:16]),
        .OUT2ADDRESS(INSTRUCTION[26:24]),
        .OUT1DATA(OPERAND1),
        .OUT2DATA(OPERAND2),
        .WRITE(REG_WRITE_ENABLE),
        .CLK(CLK),
        .RESET(RESET)
    ); 

    reg [7:0] ALU_IN_DATA1, ALU_IN_DATA2; // ALU input registers

    // ALU input selection logic: chooses between register and immediate, handles subtraction
    always @(*) begin
        ALU_IN_DATA1 = OPERAND1; // First ALU input is always from register file
        if (OPERAND_CONTROL) begin
            ALU_IN_DATA2 = INSTRUCTION[31:24]; // Use immediate value from instruction
        end
        else begin
            if (SIGN_CONTROL) begin
                ALU_IN_DATA2 <= #2 (~OPERAND2 + 8'b1); // Two's complement for subtraction/negation
            end
            else begin
                ALU_IN_DATA2 = OPERAND2; // Use register value
            end
        end
    end    

    // ALU: performs arithmetic and logic operations
    aluUnit u_alu (
        .DATA1(ALU_IN_DATA1),
        .DATA2(ALU_IN_DATA2),
        .ALUOP(ALUOP),
        .RESULT(ALURESULT),
        .ZERO(ZERO_FLAG)
    );
endmodule