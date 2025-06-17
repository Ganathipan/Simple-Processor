module forwardUnit(
    input  [7:0] DATA2,    // 8-bit input DATA2
    input        ENABLE,   // Enable signal
    output [7:0] RESULT    // 8-bit output RESULT
    );
    assign #1 RESULT = ENABLE ? DATA2 : 8'b0; // Forward DATA2 to RESULT after 1 time unit if enabled
endmodule

module addUnit(
    input  [7:0] DATA1,    // 8-bit input DATA1
    input  [7:0] DATA2,    // 8-bit input DATA2
    input        ENABLE,   // Enable signal
    output [7:0] RESULT    // 8-bit output RESULT
    );
    assign #2 RESULT = ENABLE ? (DATA1 + DATA2) : 8'b0; // Add DATA1 and DATA2, delay 2 time units if enabled
endmodule

module andUnit(
    input  [7:0] DATA1,    // 8-bit input DATA1
    input  [7:0] DATA2,    // 8-bit input DATA2
    input        ENABLE,   // Enable signal
    output [7:0] RESULT    // 8-bit output RESULT
    );
    assign #1 RESULT = ENABLE ? (DATA1 & DATA2) : 8'b0; // Bitwise AND, delay 1 time unit if enabled
endmodule

module orUnit(
    input  [7:0] DATA1,    // 8-bit input DATA1
    input  [7:0] DATA2,    // 8-bit input DATA2
    input        ENABLE,   // Enable signal
    output [7:0] RESULT    // 8-bit output RESULT
    );
    assign #1 RESULT = ENABLE ? (DATA1 | DATA2) : 8'b0; // Bitwise OR, delay 1 time unit if enabled
endmodule

module aluUnit(
    input [7:0] DATA1,        // 8-bit input DATA1
    input [7:0] DATA2,        // 8-bit input DATA2
    input [2:0] SELECT,     // 3-bit selector to choose operation
    output reg [7:0] RESULT,   // 8-bit output RESULT
    output reg ZERO
    );

    wire [7:0] sum, andOut, orOut, fwdOut;

    wire enable_fwd = (SELECT == 3'b000);
    wire enable_add = (SELECT == 3'b001);
    wire enable_and = (SELECT == 3'b010);
    wire enable_or  = (SELECT == 3'b011);

    forwardUnit u0 (.RESULT(fwdOut), .DATA2(DATA1), .ENABLE(enable_fwd));
    addUnit     u1 (.RESULT(sum), .DATA1(DATA1), .DATA2(DATA2), .ENABLE(enable_add));
    andUnit     u3 (.RESULT(andOut), .DATA1(DATA1), .DATA2(DATA2), .ENABLE(enable_and));
    orUnit      u4 (.RESULT(orOut), .DATA1(DATA1), .DATA2(DATA2), .ENABLE(enable_or));

    always @(DATA1, DATA2) begin
        ZERO = (sum == 0) ? 1'b1: 1'b0;               // Sets the ZERO flag if the result is zero
    end
    
    always @(*) begin
        case (SELECT)
            3'b000: RESULT = fwdOut;    
            3'b001: RESULT = sum;      
            3'b010: RESULT = andOut;  
            3'b011: RESULT = orOut;    
            default: RESULT = 8'b0; 
        endcase
    end
endmodule

module reg_file(
    input [7:0] IN,           
    input [2:0] INADDRESS,   
    input [2:0] OUT1ADDRESS,  
    input [2:0] OUT2ADDRESS,
    output reg [7:0] OUT1,
    output reg [7:0] OUT2,  
    input CLK, RESET, WRITE  
    );

    reg [7:0] register [0:7]; 

    always @(*) begin
        OUT1 = #2 register[OUT1ADDRESS];	
        OUT2 = #2 register[OUT2ADDRESS];
    end

    always @(posedge CLK) begin
        if(WRITE == 1'b1  &&  RESET == 1'b0) begin 
            register[INADDRESS] <= #1 IN;
        end
    end

    integer counter;             
    always @(posedge CLK) begin
        if(RESET == 1'b1) begin
            for(counter = 0; counter < 8; counter = counter + 1) begin
                register[counter] <= #1 8'b00000000;
            end
        end
    end
endmodule

module ProgramCounter(
    input CLK, RESET,
    input      [31:0] pc_in,
    output reg [31:0] pc_out
    );

    always @(posedge CLK, RESET) begin 
        if (RESET) begin
            pc_out <= #1 32'b0;
        end
        else begin
            pc_out <= #1 pc_in;
        end
    end
endmodule

module control_unit(
    input [7:0] opcode,
    output reg writeEn,
    output reg [2:0] ALUOP,
    output reg signControl,
    output reg operandControl,
    output reg branchControl,
    output reg jumpControl
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

    always @(opcode) begin 
        #1 // Delay decoding

        ALUOP = (opcode == OP_ADD)   ? 3'b001 :
                (opcode == OP_SUB)   ? 3'b001 :
                (opcode == OP_AND)   ? 3'b010 :
                (opcode == OP_OR)    ? 3'b011 :
                (opcode == OP_MOV)   ? 3'b000 :
                (opcode == OP_LOADI) ? 3'b000 :
                3'b000;


        branchControl   = (opcode == OP_BEQ)   ? 1'b1 : 1'b0;

        jumpControl     = (opcode == OP_J)     ? 1'b1 : 1'b0;

        signControl     = (opcode == OP_SUB)   ? 1'b1 : 1'b0;

        operandControl  = (opcode == OP_LOADI) ? 1'b1 : 1'b0;

        writeEn  = (opcode == OP_LOADI || opcode == OP_MOV || opcode == OP_ADD ||
                    opcode == OP_SUB || opcode == OP_AND || opcode == OP_OR) ? 1'b1 : 1'b0;
    end
endmodule

module pcIncrementer (
    input [31:0] pc_in,
    input [7:0]  branchAddress,
    input        branch, jump, zero,
    output reg [31:0] pc_out
    );

    reg [31:0] PC;
    reg [31:0] offset;

    always @(pc_in) begin
        #1 PC = pc_in + 32'd4;
    end

    always @(branchAddress) begin 
        #1 offset = {{22{branchAddress[7]}}, branchAddress, 2'b00}; 
        #1 offset = PC + offset;
    end

    always @(branch, jump, zero) begin 
        pc_out = jump ? offset : (branch && zero) ? offset : PC;
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
    wire signControl, operandControl;

    wire branchControl, jumpControl;
    wire zeroFlag;              // to control the gates for beq instruction
    wire [31:0] PC_IN;

    ProgramCounter u_pc (
        .CLK(CLK),
        .RESET(RESET),
        .pc_in(PC_IN),
        .pc_out(PC_OUT)
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

    pcIncrementer u_pcIncrementer (
        .pc_in(PC_OUT),
        .branchAddress(INSTRUCTION[15:8]),
        .branch(branchControl), 
        .jump(jumpControl), 
        .zero(zeroFlag),
        .pc_out(PC_IN)
    );

    control_unit u_control (
        .opcode(INSTRUCTION[7:0]),
        .writeEn(REG_WRITE_ENABLE),
        .ALUOP(ALUOP),
        .signControl(signControl),
        .operandControl(operandControl),
        .branchControl(branchControl),
        .jumpControl(jumpControl)
    ); 

    reg [7:0] alu_data1, alu_data2;

    always @(*) begin
        alu_data2 = OPERAND2;
        if (operandControl) begin
            alu_data1 = INSTRUCTION[31:24];
        end
        else begin
            if (signControl) begin
                #2 alu_data1 = (~OPERAND1 + 8'b1);
            end
            else begin
                alu_data1 <= OPERAND1;
            end
        end
    end

    aluUnit u_alu (
        .DATA1(alu_data1),
        .DATA2(alu_data2),
        .SELECT(ALUOP),
        .RESULT(ALURESULT),
        .ZERO(zeroFlag)
    );
endmodule
