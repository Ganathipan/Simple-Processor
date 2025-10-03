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

    // Enhanced test task for systematic testing
    task run_multiply_test;
        input [7:0] multiplicand;
        input [7:0] multiplier;
        input [79:0] test_name;
        reg [15:0] expected_full;
        reg [7:0] expected_result;
        integer start_time, end_time, cycles;
        begin
            // Calculate expected results
            expected_full = multiplicand * multiplier;
            expected_result = expected_full[7:0];  // Lower 8 bits only
            
            @(negedge clk);
            $display("\n=== %s ===", test_name);
            $display("Inputs: %0d × %0d = %0d (0x%04h)", multiplicand, multiplier, expected_full, expected_full);
            $display("Expected 8-bit result: %0d (0x%02h)", expected_result, expected_result);
            
            a = multiplicand;
            b = multiplier;
            start_time = $time;
            cycles = 0;
            start = 1;
            
            @(negedge clk);
            start = 0;
            
            // Count cycles and wait for completion
            while (!done) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            
            end_time = $time;
            @(negedge clk);
            
            // Report results and verification
            $display("Actual result: %0d (0x%02h)", result, result);
            $display("Execution: %0d cycles, %0d time units", cycles, end_time - start_time);
            
            if (result === expected_result) begin
                $display("✓ PASS: Multiplication correct");
                if (expected_full > 255)
                    $display("  Note: Overflow handled correctly (full result: %0d)", expected_full);
            end else begin
                $display("✗ FAIL: Expected %0d, got %0d", expected_result, result);
            end
            
            $display("=== Test Complete ===");
        end
    endtask

    // Comprehensive test sequence
    initial begin
        $display("==================================================================");
        $display("Starting Comprehensive Sequential Multiplier Testbench");
        $display("==================================================================");
        
        // Enhanced VCD file generation
        $dumpfile("Testing_Results/gtkwave_files/mult_test.vcd");
        $dumpvars(0, seq_unsigned_multiplier_tb);
        $dumpvars(1, uut.regA);           // Monitor multiplicand register
        $dumpvars(1, uut.regB);           // Monitor multiplier register  
        $dumpvars(1, uut.count);          // Monitor iteration counter
        $dumpvars(1, uut.adder_out);      // Monitor adder output
        
        // Initialize
        clk = 0;
        rst = 1;
        start = 0;
        a = 8'd0;
        b = 8'd0;

        #20;
        rst = 0;
        #10;

        // Test Pattern 1: Basic multiplication
        $display("\n--- TEST PATTERN 1: Basic Multiplication ---");
        run_multiply_test(8'd5, 8'd3, "Basic: 5 × 3");
        run_multiply_test(8'd12, 8'd10, "Basic: 12 × 10");
        run_multiply_test(8'd7, 8'd8, "Basic: 7 × 8");
        run_multiply_test(8'd15, 8'd4, "Basic: 15 × 4");

        // Test Pattern 2: Edge cases
        $display("\n--- TEST PATTERN 2: Edge Cases ---");
        run_multiply_test(8'd0, 8'd50, "Zero multiplicand");
        run_multiply_test(8'd25, 8'd0, "Zero multiplier");
        run_multiply_test(8'd1, 8'd255, "Identity: 1 × 255");
        run_multiply_test(8'd255, 8'd1, "Identity: 255 × 1");

        // Test Pattern 3: Powers of 2 (shift operations)
        $display("\n--- TEST PATTERN 3: Powers of 2 ---");
        run_multiply_test(8'd10, 8'd2, "× 2 (shift left 1)");
        run_multiply_test(8'd10, 8'd4, "× 4 (shift left 2)");
        run_multiply_test(8'd10, 8'd8, "× 8 (shift left 3)");
        run_multiply_test(8'd10, 8'd16, "× 16 (shift left 4)");

        // Test Pattern 4: Overflow scenarios
        $display("\n--- TEST PATTERN 4: Overflow Scenarios ---");
        run_multiply_test(8'd255, 8'd2, "Overflow: 255 × 2");
        run_multiply_test(8'd128, 8'd3, "Overflow: 128 × 3");
        run_multiply_test(8'd100, 8'd5, "Overflow: 100 × 5");
        run_multiply_test(8'd255, 8'd255, "Maximum: 255 × 255");

        // Test Pattern 5: Algorithm verification (check partial products)
        $display("\n--- TEST PATTERN 5: Algorithm Analysis ---");
        run_multiply_test(8'd85, 8'd51, "Algorithm: 85 × 51");  // 01010101 × 00110011
        run_multiply_test(8'd170, 8'd85, "Algorithm: 170 × 85"); // 10101010 × 01010101
        run_multiply_test(8'd3, 8'd85, "Algorithm: 3 × 85");    // 00000011 × 01010101

        // Test Pattern 6: Performance comparison
        $display("\n--- TEST PATTERN 6: Performance Analysis ---");
        run_multiply_test(8'd1, 8'd1, "Perf: Minimal");
        run_multiply_test(8'd255, 8'd170, "Perf: Complex");
        run_multiply_test(8'd64, 8'd32, "Perf: Medium");

        $display("\n==================================================================");
        $display("All multiplication tests completed!");
        $display("GTKWave Analysis Guidelines:");
        $display("1. Open seq_multiplier_comprehensive.vcd in GTKWave");
        $display("2. Key signals to observe:");
        $display("   - uut.regA: Watch multiplicand shifting left");
        $display("   - uut.regB: Watch multiplier shifting right"); 
        $display("   - uut.count: 8-cycle operation counter");
        $display("   - uut.adder_out: Partial product accumulation");
        $display("3. Verify shift-and-add algorithm operation");
        $display("4. Compare timing across different input patterns");
        $display("==================================================================");
        
        #50;
        $finish;
    end
endmodule
