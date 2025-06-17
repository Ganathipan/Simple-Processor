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
    output reg [31:0] PC_OUT
    );

    reg [31:0] PC;
    reg [31:0] offset;

    always @(*) begin
        PC <= #1 PC_IN + 32'd4;
 
        offset <= {{22{BRANCH_ADDRESS[7]}}, BRANCH_ADDRESS, 2'b00}; 
        offset <= #2 PC + offset;

        PC_OUT =    JUMP ? offset : 
                    (BRANCH == 2'b01 && ZERO) ? offset : 
                    (BRANCH == 2'b10 && !ZERO) ? offset : PC;
    end
endmodule