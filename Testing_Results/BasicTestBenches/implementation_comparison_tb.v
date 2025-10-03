// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// implementation_comparison_tb.v - Implementation Comparison Testbench
// Purpose: Comprehensive comparison between behavioral and gate-level 
//          implementations of critical processor components. Provides timing
//          analysis, functional verification, and performance comparison.
// -----------------------------------------------------------------------------

`timescale 1ns/100ps

// Implementation Comparison Testbench - Side-by-side analysis
// Compares behavioral vs gate-level implementations for educational insight
module implementation_comparison_tb;

    // Common test signals
    reg clk, rst, start;
    reg [7:0] data_in_a, data_in_b;
    reg [2:0] shift_amount;
    reg [1:0] shift_ctrl;
    
    // Behavioral ALU signals (from basicUnits.v)
    wire [7:0] behavioral_mul_result, behavioral_shift_result;
    wire behavioral_mul_enable, behavioral_shift_enable;
    
    // Gate-level signals (from hardwareUnits.v)  
    wire [7:0] gate_level_mul_result, gate_level_shift_result;
    wire gate_level_mul_done, gate_level_shift_done;
    
    // Performance monitoring
    integer behavioral_mul_time, gate_level_mul_time;
    integer behavioral_shift_time, gate_level_shift_time;
    integer test_count;
    
    // Instantiate behavioral implementations
    mulUnit behavioral_multiplier (
        .DATA1(data_in_a),
        .DATA2(data_in_b),
        .ENABLE(behavioral_mul_enable),
        .RESULT(behavioral_mul_result)
    );
    
    shifterUnit behavioral_shifter (
        .DATA1(data_in_a),
        .DATA2({2'b00, shift_ctrl, shift_amount}),
        .ENABLE(behavioral_shift_enable),
        .RESULT(behavioral_shift_result)
    );
    
    // Instantiate gate-level implementations
    seq_unsigned_multiplier gate_level_multiplier (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(data_in_a),
        .b(data_in_b),
        .result(gate_level_mul_result),
        .done(gate_level_mul_done)
    );
    
    gate_level_seq_shifter gate_level_shifter (
        .clk(clk),
        .rst(rst),
        .start(start),
        .ctrl(shift_ctrl),
        .shift_amt(shift_amount),
        .data_in(data_in_a),
        .data_out(gate_level_shift_result),
        .done(gate_level_shift_done)
    );
    
    // Enable behavioral units when testing
    assign behavioral_mul_enable = 1'b1;
    assign behavioral_shift_enable = 1'b1;
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Comprehensive multiplication comparison task
    task compare_multiplication;
        input [7:0] a, b;
        input [63:0] test_name;
        integer start_time_behavioral, end_time_behavioral;
        integer start_time_gate_level, end_time_gate_level;
        reg [15:0] expected_full_result;
        reg [7:0] expected_result;
        begin
            test_count = test_count + 1;
            expected_full_result = a * b;
            expected_result = expected_full_result[7:0];
            
            $display("\n=== MULTIPLICATION COMPARISON: %s ===", test_name);
            $display("Inputs: %0d × %0d = %0d (Expected 8-bit: %0d)", a, b, expected_full_result, expected_result);
            
            data_in_a = a;
            data_in_b = b;
            
            // Test behavioral implementation (combinational)
            start_time_behavioral = $time;
            #2; // Allow propagation delay
            end_time_behavioral = $time;
            behavioral_mul_time = end_time_behavioral - start_time_behavioral;
            
            // Test gate-level implementation (sequential)
            @(negedge clk);
            start_time_gate_level = $time;
            start = 1;
            @(negedge clk);
            start = 0;
            wait(gate_level_mul_done);
            end_time_gate_level = $time;
            gate_level_mul_time = end_time_gate_level - start_time_gate_level;
            
            // Results comparison
            $display("Results Comparison:");
            $display("  Behavioral: %3d (0x%02h) - Time: %2d ns", 
                     behavioral_mul_result, behavioral_mul_result, behavioral_mul_time);
            $display("  Gate-Level: %3d (0x%02h) - Time: %2d ns", 
                     gate_level_mul_result, gate_level_mul_result, gate_level_mul_time);
            $display("  Expected:   %3d (0x%02h)", expected_result, expected_result);
            
            // Verification
            if (behavioral_mul_result === expected_result && gate_level_mul_result === expected_result) begin
                $display("  ✓ PASS: Both implementations correct");
                $display("  Performance: Gate-level is %0dx slower (expected for sequential)", 
                         gate_level_mul_time / behavioral_mul_time);
            end else begin
                $display("  ✗ FAIL: Mismatch detected!");
                if (behavioral_mul_result !== expected_result)
                    $display("    Behavioral implementation error");
                if (gate_level_mul_result !== expected_result)
                    $display("    Gate-level implementation error");
            end
        end
    endtask
    
    // Comprehensive shift comparison task
    task compare_shift;
        input [7:0] data;
        input [1:0] shift_type;
        input [2:0] amount;
        input [63:0] test_name;
        integer start_time_behavioral, end_time_behavioral;
        integer start_time_gate_level, end_time_gate_level;
        reg [7:0] expected_result;
        reg [7:0] temp_data;
        integer i;
        begin
            // Calculate expected result
            temp_data = data;
            for (i = 0; i < amount; i = i + 1) begin
                case (shift_type)
                    2'b00: temp_data = {temp_data[6:0], 1'b0};      // SLL
                    2'b01: temp_data = {1'b0, temp_data[7:1]};      // SRL
                    2'b10: temp_data = {temp_data[7], temp_data[7:1]}; // SRA
                    2'b11: temp_data = {temp_data[0], temp_data[7:1]}; // ROR
                endcase
            end
            expected_result = temp_data;
            
            $display("\n=== SHIFT COMPARISON: %s ===", test_name);
            $display("Input: 0x%02h (%b), Type: %s, Amount: %0d", 
                     data, data,
                     (shift_type == 2'b00) ? "SLL" :
                     (shift_type == 2'b01) ? "SRL" :
                     (shift_type == 2'b10) ? "SRA" : "ROR", amount);
            
            data_in_a = data;
            shift_ctrl = shift_type;
            shift_amount = amount;
            
            // Test behavioral implementation
            start_time_behavioral = $time;
            #2; // Allow propagation
            end_time_behavioral = $time;
            behavioral_shift_time = end_time_behavioral - start_time_behavioral;
            
            // Test gate-level implementation
            @(negedge clk);
            start_time_gate_level = $time;
            start = 1;
            @(negedge clk);
            start = 0;
            wait(gate_level_shift_done);
            end_time_gate_level = $time;
            gate_level_shift_time = end_time_gate_level - start_time_gate_level;
            
            // Results comparison
            $display("Results Comparison:");
            $display("  Behavioral: 0x%02h (%b) - Time: %2d ns", 
                     behavioral_shift_result, behavioral_shift_result, behavioral_shift_time);
            $display("  Gate-Level: 0x%02h (%b) - Time: %2d ns", 
                     gate_level_shift_result, gate_level_shift_result, gate_level_shift_time);
            $display("  Expected:   0x%02h (%b)", expected_result, expected_result);
            
            // Verification
            if (behavioral_shift_result === expected_result && gate_level_shift_result === expected_result) begin
                $display("  ✓ PASS: Both implementations correct");
                $display("  Performance: Gate-level took %0d cycles (%0d ns vs %0d ns)", 
                         amount, gate_level_shift_time, behavioral_shift_time);
            end else begin
                $display("  ✗ FAIL: Mismatch detected!");
            end
        end
    endtask

    // Main test sequence
    initial begin
        $display("====================================================================");
        $display("Implementation Comparison Testbench");
        $display("Behavioral vs Gate-Level Implementation Analysis");  
        $display("====================================================================");
        
        // Enhanced waveform generation for comparison analysis
        $dumpfile("Testing_Results/gtkwave_files/implementation_comparison.vcd");
        $dumpvars(0, implementation_comparison_tb);
        
        // Monitor internal signals for detailed analysis
        $dumpvars(1, behavioral_multiplier);
        $dumpvars(1, behavioral_shifter);
        $dumpvars(1, gate_level_multiplier.regA);
        $dumpvars(1, gate_level_multiplier.regB);
        $dumpvars(1, gate_level_multiplier.count);
        $dumpvars(1, gate_level_shifter.shift_reg);
        $dumpvars(1, gate_level_shifter.count);
        $dumpvars(1, gate_level_shifter.target);
        
        // Initialize
        clk = 0;
        rst = 1;
        start = 0;
        data_in_a = 0;
        data_in_b = 0;
        shift_amount = 0;
        shift_ctrl = 0;
        test_count = 0;
        
        #20;
        rst = 0;
        #10;
        
        $display("\n--- MULTIPLICATION COMPARISON TESTS ---");
        
        // Basic multiplication tests
        compare_multiplication(8'd5, 8'd3, "Basic: 5 × 3");
        compare_multiplication(8'd12, 8'd10, "Medium: 12 × 10");
        compare_multiplication(8'd255, 8'd2, "Overflow: 255 × 2");
        compare_multiplication(8'd0, 8'd100, "Zero factor");
        compare_multiplication(8'd255, 8'd255, "Maximum: 255 × 255");
        
        // Algorithm-specific tests
        compare_multiplication(8'd85, 8'd51, "Pattern: 01010101 × 00110011");
        compare_multiplication(8'd170, 8'd85, "Pattern: 10101010 × 01010101");
        
        $display("\n--- SHIFT COMPARISON TESTS ---");
        
        // Shift operation tests
        compare_shift(8'b10110011, 2'b00, 3'd2, "SLL by 2");
        compare_shift(8'b10110011, 2'b01, 3'd3, "SRL by 3");  
        compare_shift(8'b10110011, 2'b10, 3'd2, "SRA by 2");
        compare_shift(8'b10110011, 2'b11, 3'd4, "ROR by 4");
        
        // Edge cases
        compare_shift(8'b11111111, 2'b10, 3'd7, "SRA: All ones by 7");
        compare_shift(8'b10000001, 2'b11, 3'd1, "ROR: Edge pattern");
        compare_shift(8'b00000000, 2'b00, 3'd5, "SLL: All zeros");
        
        $display("\n--- PERFORMANCE ANALYSIS SUMMARY ---");
        $display("Implementation Characteristics:");
        $display("1. BEHAVIORAL (Combinational):");
        $display("   - Instant result (limited by propagation delay)");
        $display("   - Higher area cost (parallel logic)");
        $display("   - Suitable for high-performance processors");
        $display("2. GATE-LEVEL SEQUENTIAL:");
        $display("   - Multi-cycle execution");
        $display("   - Lower area cost (reused components)");
        $display("   - Suitable for area-constrained designs");
        
        $display("\n--- EDUCATIONAL INSIGHTS ---");
        $display("Key Learning Points:");
        $display("1. Trade-offs between speed and area in hardware design");
        $display("2. Behavioral modeling vs structural implementation");
        $display("3. Sequential vs combinational design approaches");
        $display("4. Verification methods for different implementation styles");
        
        $display("\n====================================================================");
        $display("Implementation Comparison Completed!");
        $display("");
        $display("GTKWave Analysis Instructions:");
        $display("1. Open implementation_comparison.vcd in GTKWave");
        $display("2. Create signal groups for comparison:");
        $display("   Group 1 - Inputs & Control:");
        $display("     - clk, rst, start");
        $display("     - data_in_a, data_in_b, shift_ctrl, shift_amount");
        $display("   Group 2 - Behavioral Results:");
        $display("     - behavioral_mul_result, behavioral_shift_result");
        $display("   Group 3 - Gate-Level Results:");  
        $display("     - gate_level_mul_result, gate_level_shift_result");
        $display("     - gate_level_mul_done, gate_level_shift_done");
        $display("   Group 4 - Internal Gate-Level Signals:");
        $display("     - gate_level_multiplier.regA, regB, count");
        $display("     - gate_level_shifter.shift_reg, count, target");
        $display("3. Analysis focuses:");
        $display("   - Compare result accuracy between implementations");
        $display("   - Observe timing differences (instant vs multi-cycle)");
        $display("   - Study internal algorithm progression in gate-level");
        $display("   - Understand hardware complexity trade-offs");
        $display("====================================================================");
        
        #100;
        $finish;
    end

endmodule