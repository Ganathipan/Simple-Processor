// -----------------------------------------------------------------------------
// Authors: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]  
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// seq_unsigned_multiplier_tb.v - Sequential Multiplier Testbench
// Purpose: Verification testbench for gate-level sequential multiplier using
//          shift-and-add algorithm. Tests various multiplication scenarios
//          including edge cases and generates timing analysis waveforms.
// -----------------------------------------------------------------------------

// Sequential Multiplier Testbench - Verification environment for gate-level multiplier  
// Provides systematic testing of 8-bit multiplication with overflow handling
module seq_unsigned_multiplier_tb;

    // Testbench Control Signals
    reg clk;                        // Test clock generation
    reg rst;                        // Reset signal for multiplier
    reg start;                      // Start multiplication operation
    reg [7:0] a, b;                 // 8-bit multiplicand and multiplier inputs
    
    // Testbench Monitor Signals  
    wire [7:0] result;              // 8-bit multiplication result (lower bits)
    wire done;                      // Multiplication completion flag

    // Instantiate the multiplier
    seq_unsigned_multiplier uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .result(result),
        .done(done)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        // Waveform dump
        $dumpfile("GateLevelModues/seq_unsigned_multiplier.vcd");  // VCD output file
        $dumpvars(0, seq_unsigned_multiplier_tb);  // Dump all signals recursively

        // Initial values
        clk = 0;
        rst = 1;
        start = 0;
        a = 8'd0;
        b = 8'd0;

        #20;
        rst = 0;

        // Test Case 1: 5 * 3 = 15
        a = 8'd5;
        b = 8'd3;
        start = 1;
        #10;
        start = 0;
        wait (done == 1);
        #10;

        // Test Case 2: 12 * 10 = 120
        a = 8'd12;
        b = 8'd10;
        start = 1;
        #10;
        start = 0;
        wait (done == 1);
        #10;

        // Test Case 3: 255 * 2 = 510 → lower 8 bits = 254
        a = 8'd255;
        b = 8'd2;
        start = 1;
        #10;
        start = 0;
        wait (done == 1);
        #10;

        // Test Case 4: 0 * 50 = 0
        a = 8'd0;
        b = 8'd50;
        start = 1;
        #10;
        start = 0;
        wait (done == 1);
        #10;

        $finish;
    end
endmodule
