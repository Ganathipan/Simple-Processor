// -----------------------------------------------------------------------------
// Authors: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// seq_shifter_tb.v - Gate-Level Sequential Shifter Testbench
// Purpose: Comprehensive verification testbench for the gate-level sequential
//          shifter implementation. Tests all shift types (SLL, SRL, SRA, ROR)
//          with various shift amounts and generates waveforms for analysis.
// -----------------------------------------------------------------------------

// Gate-Level Shifter Testbench - Verification environment for sequential shifter
// Provides systematic testing of all shift operations with automated test tasks
module gate_level_seq_shifter_tb;

    // Testbench Input Signals (driven by testbench)
    reg clk;                        // Test clock generation
    reg rst;                        // Reset control for UUT  
    reg start;                      // Start signal for shift operation
    reg [1:0] ctrl;                 // Shift type control (00=SLL, 01=SRL, 10=SRA, 11=ROR)
    reg [2:0] shift_amt;            // Shift amount (0-7 positions)
    reg [7:0] data_in;              // Input data to be shifted

    // Testbench Output Signals (monitored from UUT)
    wire [7:0] data_out;            // Shifted output data
    wire done;                      // Completion flag from shifter

    // Instantiate the Unit Under Test (UUT)
    gate_level_seq_shifter uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .ctrl(ctrl),
        .shift_amt(shift_amt),
        .data_in(data_in),
        .data_out(data_out),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Enhanced test task with detailed analysis and timing verification
    task run_test;
        input [1:0] t_ctrl;
        input [2:0] t_amt;
        input [7:0] t_data;
        input [79:0] test_name;  // String description for test
        reg [7:0] expected_result;
        integer start_time, end_time;
        begin
            // Calculate expected result for comparison
            expected_result = calculate_expected(t_ctrl, t_amt, t_data);
            
            @(negedge clk);
            $display("\n=== Starting Test: %s ===", test_name);
            $display("Input: DATA=0x%02h (%b), CTRL=%b (%s), SHIFT_AMT=%0d", 
                     t_data, t_data, t_ctrl, get_shift_name(t_ctrl), t_amt);
            
            ctrl      = t_ctrl;
            shift_amt = t_amt;
            data_in   = t_data;
            start_time = $time;
            start     = 1;
            
            @(negedge clk);
            start     = 0;

            // Wait for completion and measure timing
            wait(done == 1);
            end_time = $time;
            @(negedge clk);
            
            // Verify result and report
            $display("Output: 0x%02h (%b)", data_out, data_out);
            $display("Expected: 0x%02h (%b)", expected_result, expected_result);
            $display("Execution Time: %0d time units", end_time - start_time);
            
            if (data_out === expected_result) 
                $display("✓ PASS: Result matches expected value");
            else 
                $display("✗ FAIL: Result mismatch!");
                
            $display("=== Test Complete ===\n");
        end
    endtask
    
    // Function to calculate expected shift result
    function [7:0] calculate_expected;
        input [1:0] ctrl;
        input [2:0] amt;
        input [7:0] data;
        reg [7:0] temp;
        integer i;
        begin
            temp = data;
            for (i = 0; i < amt; i = i + 1) begin
                case (ctrl)
                    2'b00: temp = {temp[6:0], 1'b0};          // SLL
                    2'b01: temp = {1'b0, temp[7:1]};          // SRL
                    2'b10: temp = {temp[7], temp[7:1]};       // SRA
                    2'b11: temp = {temp[0], temp[7:1]};       // ROR
                endcase
            end
            calculate_expected = temp;
        end
    endfunction
    
    // Function to get shift operation name
    function [31:0] get_shift_name;
        input [1:0] ctrl;
        begin
            case (ctrl)
                2'b00: get_shift_name = "SLL";
                2'b01: get_shift_name = "SRL"; 
                2'b10: get_shift_name = "SRA";
                2'b11: get_shift_name = "ROR";
            endcase
        end
    endfunction

    // Comprehensive test sequence with multiple test patterns
    initial begin
        $display("=================================================================");
        $display("Starting Comprehensive Gate-Level Sequential Shifter Testbench");
        $display("=================================================================");
        
        // Enhanced VCD file generation for GTKWave analysis
        $dumpfile("Testing_Results/gtkwave_files/seq_shifter_comprehensive.vcd");
        $dumpvars(0, gate_level_seq_shifter_tb);
        $dumpvars(1, uut.shift_reg);         // Monitor internal shift register
        $dumpvars(1, uut.count);             // Monitor shift counter
        $dumpvars(1, uut.target);            // Monitor target shift amount
        $dumpvars(1, uut.busy);              // Monitor busy flag
        $dumpvars(1, uut.ctrl_00);           // Monitor decoded control signals
        $dumpvars(1, uut.ctrl_01);
        $dumpvars(1, uut.ctrl_10);
        $dumpvars(1, uut.ctrl_11);
        
        // Initialize signals
        clk = 0;
        rst = 1;
        start = 0;
        ctrl = 2'b00;
        shift_amt = 3'b000;
        data_in = 8'h00;

        #20;
        rst = 0;
        #10;

        // Test Pattern 1: Basic functionality with standard test data
        $display("\n--- TEST PATTERN 1: Basic Functionality ---");
        run_test(2'b00, 3'd1, 8'b10110011, "SLL by 1 - Basic");
        run_test(2'b01, 3'd2, 8'b10110011, "SRL by 2 - Basic"); 
        run_test(2'b10, 3'd3, 8'b10110011, "SRA by 3 - Basic");
        run_test(2'b11, 3'd4, 8'b10110011, "ROR by 4 - Basic");

        // Test Pattern 2: Edge cases - all zeros and all ones
        $display("\n--- TEST PATTERN 2: Edge Cases ---");
        run_test(2'b00, 3'd3, 8'b00000000, "SLL Zeros");
        run_test(2'b01, 3'd3, 8'b11111111, "SRL Ones");
        run_test(2'b10, 3'd4, 8'b11111111, "SRA Negative");
        run_test(2'b11, 3'd7, 8'b10000001, "ROR Maximum");

        // Test Pattern 3: Boundary conditions
        $display("\n--- TEST PATTERN 3: Boundary Conditions ---");
        run_test(2'b00, 3'd0, 8'b10101010, "SLL by 0");
        run_test(2'b01, 3'd7, 8'b10000000, "SRL Maximum");
        run_test(2'b10, 3'd7, 8'b10000000, "SRA Maximum Negative");
        run_test(2'b11, 3'd1, 8'b00000001, "ROR Single Bit");

        // Test Pattern 4: Sign extension verification for SRA
        $display("\n--- TEST PATTERN 4: Sign Extension Tests ---");
        run_test(2'b10, 3'd1, 8'b11000000, "SRA Negative Sign");
        run_test(2'b10, 3'd1, 8'b01000000, "SRA Positive Sign");
        run_test(2'b10, 3'd5, 8'b11111000, "SRA Heavy Negative");
        run_test(2'b10, 3'd5, 8'b01111000, "SRA Heavy Positive");

        // Test Pattern 5: Rotation patterns
        $display("\n--- TEST PATTERN 5: Rotation Verification ---");
        run_test(2'b11, 3'd1, 8'b11000001, "ROR Pattern 1");
        run_test(2'b11, 3'd2, 8'b10000011, "ROR Pattern 2");
        run_test(2'b11, 3'd4, 8'b00001111, "ROR Pattern 3");
        run_test(2'b11, 3'd8, 8'b10101010, "ROR Full Circle");

        // Test Pattern 6: Performance analysis - different shift amounts
        $display("\n--- TEST PATTERN 6: Performance Analysis ---");
        run_test(2'b00, 3'd1, 8'hAA, "Perf: Shift 1");
        run_test(2'b00, 3'd2, 8'hAA, "Perf: Shift 2");
        run_test(2'b00, 3'd4, 8'hAA, "Perf: Shift 4");
        run_test(2'b00, 3'd7, 8'hAA, "Perf: Shift 7");

        $display("\n=================================================================");
        $display("All tests completed! Check seq_shifter_comprehensive.vcd in GTKWave");
        $display("Key signals to observe:");
        $display("- uut.shift_reg: Internal shifting progression");
        $display("- uut.count vs uut.target: Progress tracking");
        $display("- uut.ctrl_xx: Decoded control signals");
        $display("- Timing relationships between start, busy, and done");
        $display("=================================================================");
        
        #50;  // Allow time for final observations
        $finish;
    end

endmodule
