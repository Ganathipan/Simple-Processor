// -----------------------------------------------------------------------------
// Authors: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22  
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// hardwareUnits.v - Gate-Level Sequential Hardware Implementations
// Purpose: Contains gate-level implementations of complex arithmetic operations
//          (shifter and multiplier) using only basic logic gates and FSM control.
//          Demonstrates how high-level operations are built from fundamental gates.
// -----------------------------------------------------------------------------

// Gate-Level Sequential Shifter - FSM-controlled universal shifter
// Implements all shift types using only basic gates (NAND, AND) with sequential operation
// Provides educational insight into hardware construction principles
module gate_level_seq_shifter (
    input clk,                  // System clock for sequential operation
    input rst,                  // Asynchronous reset (active high)
    input start,                // Start signal to begin shift operation
    input [1:0] ctrl,           // 2-bit control: 00=SLL, 01=SRL, 10=SRA, 11=ROR
    input [2:0] shift_amt,      // Shift amount (0-7 positions)
    input [7:0] data_in,        // 8-bit input data to be shifted
    output reg [7:0] data_out,  // 8-bit final shifted output
    output reg done             // Done flag indicating completion
);

    // Internal state registers for FSM operation
    reg [7:0] shift_reg;        // Internal shift register holding current data
    reg [2:0] count;            // Counter tracking number of shifts performed
    reg [2:0] target;           // Target shift amount (latched from shift_amt)
    reg busy;                   // Internal busy flag for FSM control

    // Gate-level control signal decoding wires
    wire ctrl0_n, ctrl1_n;      // Inverted control bits
    wire ctrl_00, ctrl_01, ctrl_10, ctrl_11;  // Decoded control signals

    // Control decoding using only basic NAND and AND gates
    nand(ctrl0_n, ctrl[0], ctrl[0]);   // Generate ~ctrl[0] using NAND gate
    nand(ctrl1_n, ctrl[1], ctrl[1]);   // Generate ~ctrl[1] using NAND gate

    and(ctrl_00, ctrl1_n, ctrl0_n);    // 00: Logical Left Shift
    and(ctrl_01, ctrl1_n, ctrl[0]);    // 01: Logical Right Shift  
    and(ctrl_10, ctrl[1],  ctrl0_n);   // 10: Arithmetic Right Shift
    and(ctrl_11, ctrl[1],  ctrl[0]);   // 11: Rotate Right

    integer i;                  // Loop variable for gate-level bit manipulation

    // Temporary register for manual gate-level shifting logic
    reg [7:0] next_val;        // Next value after one shift operation

    // FSM Sequential Logic - Controls the shifting state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'b0;
            data_out  <= 8'b0;
            count     <= 3'b0;
            done      <= 1'b0;
            busy      <= 1'b0;
            target    <= 3'b0;
        end else if (start && !busy) begin
            shift_reg <= data_in;
            target    <= shift_amt;
            count     <= 3'b0;
            busy      <= 1'b1;
            done      <= 1'b0;
        end else if (busy && !done) begin
            
            // Manual gate-level shifting
            next_val = 8'b0;

            // Default: no change
            for (i = 0; i < 8; i = i + 1) begin
                next_val[i] = shift_reg[i];
            end

            // Logic for each shift mode
            // 00: Logical Left Shift
            if (ctrl_00) begin
                for (i = 7; i > 0; i = i - 1) begin
                    next_val[i] = shift_reg[i-1];
                end
                next_val[0] = 1'b0;
            end

            // 01: Logical Right Shift
            if (ctrl_01) begin
                for (i = 0; i < 7; i = i + 1)
                    next_val[i] = shift_reg[i+1];
                next_val[7] = 1'b0;
            end

            // 10: Arithmetic Right Shift
            if (ctrl_10) begin
                for (i = 0; i < 7; i = i + 1)
                    next_val[i] = shift_reg[i+1];
                next_val[7] = shift_reg[7]; // Sign extension
            end

            // 11: Rotate Right
            if (ctrl_11) begin
                for (i = 0; i < 7; i = i + 1)
                    next_val[i] = shift_reg[i+1];
                next_val[7] = shift_reg[0];
            end

            shift_reg <= next_val;
            count <= count + 1;

            if (count == target - 1) begin
                data_out <= next_val;
                done     <= 1'b1;
                busy     <= 1'b0;
            end
        end
    end
endmodule

// Sequential Unsigned Multiplier - Gate-level 8-bit multiplier implementation
// Uses shift-and-add algorithm with manual full adder construction
// Demonstrates binary multiplication at the hardware level using basic gates
module seq_unsigned_multiplier (
    input clk,                  // System clock for sequential operation
    input rst,                  // Reset signal (active high)
    input start,                // Start signal to begin multiplication
    input [7:0] a,              // 8-bit multiplicand (first operand)
    input [7:0] b,              // 8-bit multiplier (second operand)
    output reg [7:0] result,    // 8-bit result (lower bits of 16-bit product)
    output reg done             // Done flag indicating completion
);

    // Internal registers for shift-and-add multiplication algorithm
    reg [15:0] regA;            // Shift register A: multiplicand (shifted left each cycle)
    reg [15:0] regB;            // Shift register B: multiplier + accumulator (shifted right)
    reg [3:0] count;            // Loop counter for 8-bit multiplication (0 to 7)

    reg [15:0] adder_out;       // Output from the 16-bit full adder
    reg add_enable;             // Control signal for conditional addition

    integer i;                  // Loop variable for gate-level adder implementation

    // Full 16-bit adder using AND/OR
    function [15:0] full_adder_16bit;
        input [15:0] x, y;
        reg [15:0] sum;
        reg carry;
        reg a_bit, b_bit, s_bit, c1, c2, c3;
        integer j;
        begin
            carry = 0;
            for (j = 0; j < 16; j = j + 1) begin
                a_bit = x[j];
                b_bit = y[j];

                // sum = a ^ b ^ carry (built with AND/OR/NOT)
                s_bit = (a_bit ^ b_bit) ^ carry;
                sum[j] = s_bit;

                // carry-out = majority(a, b, carry)
                c1 = a_bit & b_bit;
                c2 = a_bit & carry;
                c3 = b_bit & carry;
                carry = c1 | c2 | c3;
            end
            full_adder_16bit = sum;
        end
    endfunction

    // Control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            regA    <= 16'b0;
            regB    <= 16'b0;
            adder_out <= 16'b0;
            result  <= 8'b0;
            count   <= 4'd0;
            done    <= 1'b0;
            add_enable <= 1'b0;
        end else if (start) begin
            regA <= {8'b0, a};    // multiplicand in lower 8 bits, aligned left
            regB <= {8'b0, b};    // multiplier in lower 8 bits, accumulator in upper
            count <= 4'd0;
            adder_out <= 16'b0;
            done <= 1'b0;
        end else if (count < 8) begin
            // Check LSB of regB (multiplier)
            if (regB[0]) begin
                // Add regA to upper 16 bits of regB using full adder
                adder_out = full_adder_16bit(adder_out, regA);
                //regB = adder_out;
            end

            // Shift regA left by 1 (<< 1)
            regA = {regA[14:0], 1'b0};

            // Shift regB right by 1 (>> 1)
            regB = {1'b0, regB[15:1]};

            count = count + 1;

            if (count == 7) begin
                result <= adder_out[7:0]; // output lower 8 bits only
                done <= 1'b1;
            end
        end
    end
endmodule
