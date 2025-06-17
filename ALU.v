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
    output reg signed [15:0] RESULT // Final 16-bit signed product
    );

    reg signed [15:0] A;            // +Multiplicand shifted left
    reg signed [15:0] S;            // -Multiplicand shifted left
    reg signed [16:0] P;            // Product register: {A[7:0], Q[7:0], Q-1}
    integer i;

    always @(*) begin
            // Prepare multiplicand (+ and - versions)
            A = {DATA1, 8'b0};       // Left shift multiplicand by 8 bits
            S = {-DATA1, 8'b0};      // Left shift negative multiplicand

            // Initialize P with multiplier and extra Q-1 bit
            P = {8'b0, DATA2, 1'b0}; // {accumulator=0, multiplier, Q-1=0}

            // Booth's Algorithm Iteration
            for (i = 0; i < 8; i = i + 1) begin
                case (P[1:0])  // Examine Q0 and Q-1
                    2'b01: P[16:1] = P[16:1] + A; // Add A
                    2'b10: P[16:1] = P[16:1] + S; // Subtract A (add -A)
                    default: ;                   // No operation
                endcase

                // Arithmetic right shift of P (preserve sign)
                P = {P[16], P[16:1]};
            end

            // Assign final result (ignore Q-1 bit)
            #3 RESULT = P[8:1]; 
    end
endmodule

module shifterUnit (    
    input  [7:0] DATA1,     // 8-bit input DATA1
    input  [7:0] DATA2,     // 8-bit input DATA2
    output reg [7:0] RESULT // 8-bit output RESULT
    );

    integer i;
    reg sign;

    always @(*) begin
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
        #4; // Delay for shifting
    end
endmodule
