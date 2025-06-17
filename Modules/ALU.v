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