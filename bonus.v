module mulUnit(
    input  [7:0] DATA1,    // 8-bit input DATA1
    input  [7:0] DATA2,    // 8-bit input DATA2
    input        ENABLE,   // Enable signal
    output [7:0] RESULT    // 8-bit output RESULT
    );

    // Booth's Algorithm 
    integer i;
    reg [15:0] temp1, temp2;

    always @(*) begin
        temp1 = 16'b0;
        temp2 = 16'b0;

        for (i = 0; i < 8; i = i + 1) begin
            temp2 = {DATA1, 1'b0};
            if (DATA2[i])
                temp1 = temp1 + temp2;
        end
    end

    assign RESULT = ENABLE ? temp1[7:0] : 8'b0;
endmodule

module shifter (     // FWD unit updated to handle shift
    input  [7:0] DATA1,    // 8-bit input DATA1
    input  [7:0] DATA2,    // 8-bit input DATA2
    input        ENABLE,   // Enable signal
    output reg [7:0] RESULT    // 8-bit output RESULT
    );

    integer i;
    reg [7:0] temp;
    reg sign;

    always @(*) begin 
        
        RESULT = ENABLE ? DATA1 : 8'b0;     
        sign = DATA1[7];
        for (i = 0; i < DATA2[3:0]; i = i + 1) begin
            case(DATA2[5:4])
                3'b001: RESULT = {RESULT[6:0], 1'b0};                 // sll
                3'b010: RESULT = {1'b0, RESULT[7:1]};                 // srl
                3'b011: RESULT = {sign, RESULT[7:1]};                 // sra
                3'b100: RESULT = {RESULT[0], RESULT[7:1]};            // ror
                default: RESULT = RESULT;
            endcase
        end
    end
endmodule