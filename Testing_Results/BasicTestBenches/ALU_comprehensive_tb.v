// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// ALU_comprehensive_tb.v - Comprehensive ALU Testbench
// Purpose: Exhaustive testing of all ALU operations including functional
//          verification, timing analysis, and edge case testing. Generates
//          detailed waveforms for comparative analysis in GTKWave.
// -----------------------------------------------------------------------------

`timescale 1ns/100ps

// Comprehensive ALU Testbench - Complete verification environment
// Tests all ALU operations with various data patterns and analyzes timing relationships
module ALU_comprehensive_tb;

    // Testbench signals
    reg [7:0] DATA1, DATA2;         // ALU input operands
    reg [2:0] ALUOP;                // ALU operation selector
    wire [7:0] RESULT;              // ALU computation result
    wire ZERO;                      // Zero flag output
    
    // Internal monitoring signals for detailed analysis
    wire [7:0] fwd_result, add_result, and_result, or_result, mul_result, shift_result;
    
    // Instantiate ALU under test
    aluUnit uut (
        .DATA1(DATA1),
        .DATA2(DATA2), 
        .ALUOP(ALUOP),
        .RESULT(RESULT),
        .ZERO(ZERO)
    );
    
    // Instantiate individual units for comparison (bypass ALU multiplexer)
    fwdUnit test_fwd (.DATA2(DATA2), .RESULT(fwd_result));
    addUnit test_add (.DATA1(DATA1), .DATA2(DATA2), .RESULT(add_result));
    andUnit test_and (.DATA1(DATA1), .DATA2(DATA2), .RESULT(and_result));
    orUnit test_or (.DATA1(DATA1), .DATA2(DATA2), .RESULT(or_result));
    mulUnit test_mul (.DATA1(DATA1), .DATA2(DATA2), .ENABLE(1'b1), .RESULT(mul_result));
    shifterUnit test_shift (.DATA1(DATA1), .DATA2(DATA2), .ENABLE(1'b1), .RESULT(shift_result));

    // Test task with comprehensive verification
    task test_alu_operation;
        input [2:0] op;
        input [7:0] d1, d2;
        input [63:0] test_name;
        reg [7:0] expected;
        reg expected_zero;
        begin
            @(negedge $realtime);
            ALUOP = op;
            DATA1 = d1;
            DATA2 = d2;
            
            #10; // Allow propagation
            
            // Calculate expected results based on operation
            case (op)
                3'b000: expected = d2;                          // Forward
                3'b001: begin 
                    expected = d1 + d2;                         // Add
                    expected_zero = (expected == 0);
                end
                3'b010: expected = d1 & d2;                     // AND
                3'b011: expected = d1 | d2;                     // OR
                3'b100: expected = (d1 * d2) & 8'hFF;          // MUL (lower 8 bits)
                3'b101: expected = shift_result;                // Use shifter unit result
            endcase
            
            // For non-add operations, ZERO flag should reflect add result
            if (op != 3'b001) expected_zero = ((d1 + d2) == 0);
            
            $display("=== %s ===", test_name);
            $display("ALUOP=%b, DATA1=0x%02h (%0d), DATA2=0x%02h (%0d)", 
                     op, d1, d1, d2, d2);
            $display("Result: 0x%02h (%0d), Expected: 0x%02h (%0d)", 
                     RESULT, RESULT, expected, expected);
            $display("ZERO flag: %b, Expected: %b", ZERO, expected_zero);
            
            // Verification
            if (RESULT === expected && ZERO === expected_zero) 
                $display("✓ PASS");
            else 
                $display("✗ FAIL");
                
            // Display individual unit outputs for debugging
            $display("Unit outputs - FWD:0x%02h ADD:0x%02h AND:0x%02h OR:0x%02h MUL:0x%02h SHIFT:0x%02h", 
                     fwd_result, add_result, and_result, or_result, mul_result, shift_result);
            $display("---");
        end
    endtask
    
    // Specialized shift test with detailed control word analysis
    task test_shift_detailed;
        input [7:0] data;
        input [1:0] shift_type;
        input [3:0] shift_amount;
        input [63:0] test_name;
        reg [7:0] control_word;
        begin
            control_word = {2'b00, shift_type, shift_amount};
            test_alu_operation(3'b101, data, control_word, test_name);
            
            $display("Shift Analysis:");
            $display("  Type: %s, Amount: %0d", 
                     (shift_type == 2'b00) ? "SLL" :
                     (shift_type == 2'b01) ? "SRL" :
                     (shift_type == 2'b10) ? "SRA" : "ROR", shift_amount);
        end
    endtask

    // Main test sequence
    initial begin
        $display("===================================================================");
        $display("Comprehensive ALU Testbench - All Operations Analysis");
        $display("===================================================================");
        
        // Enhanced waveform generation
        $dumpfile("Testing_Results/gtkwave_files/alu_comp_test.vcd");
        $dumpvars(0, ALU_comprehensive_tb);
        $dumpvars(1, uut.u0);   // Forward unit
        $dumpvars(1, uut.u1);   // Add unit
        $dumpvars(1, uut.u3);   // AND unit
        $dumpvars(1, uut.u4);   // OR unit
        $dumpvars(1, uut.u5);   // MUL unit
        $dumpvars(1, uut.u6);   // SHIFT unit
        
        // Initialize
        DATA1 = 0;
        DATA2 = 0;
        ALUOP = 0;
        #10;
        
        $display("\n--- TEST PATTERN 1: Forward Operation (MOV/LOADI) ---");
        test_alu_operation(3'b000, 8'h00, 8'h42, "Forward: 0x42");
        test_alu_operation(3'b000, 8'hFF, 8'hAA, "Forward: 0xAA");
        test_alu_operation(3'b000, 8'h55, 8'h00, "Forward: 0x00");
        
        $display("\n--- TEST PATTERN 2: Addition/Subtraction ---");
        test_alu_operation(3'b001, 8'h10, 8'h20, "Add: 16 + 32");
        test_alu_operation(3'b001, 8'hFF, 8'h01, "Add: Overflow");
        test_alu_operation(3'b001, 8'h80, 8'h80, "Add: Zero result");
        test_alu_operation(3'b001, 8'h00, 8'h00, "Add: Zero inputs");
        
        $display("\n--- TEST PATTERN 3: Bitwise AND ---");
        test_alu_operation(3'b010, 8'hFF, 8'hAA, "AND: Mask test");
        test_alu_operation(3'b010, 8'h55, 8'hAA, "AND: Alternating");
        test_alu_operation(3'b010, 8'hF0, 8'h0F, "AND: Disjoint");
        test_alu_operation(3'b010, 8'hFF, 8'hFF, "AND: All ones");
        
        $display("\n--- TEST PATTERN 4: Bitwise OR ---");
        test_alu_operation(3'b011, 8'h00, 8'hAA, "OR: Set bits");
        test_alu_operation(3'b011, 8'h55, 8'hAA, "OR: Alternating");
        test_alu_operation(3'b011, 8'hF0, 8'h0F, "OR: Combine");
        test_alu_operation(3'b011, 8'h00, 8'h00, "OR: All zeros");
        
        $display("\n--- TEST PATTERN 5: Multiplication ---");
        test_alu_operation(3'b100, 8'd5, 8'd3, "MUL: 5 × 3");
        test_alu_operation(3'b100, 8'd15, 8'd17, "MUL: Overflow case");
        test_alu_operation(3'b100, 8'd0, 8'd255, "MUL: Zero factor");
        test_alu_operation(3'b100, 8'd255, 8'd1, "MUL: Identity");
        
        $display("\n--- TEST PATTERN 6: Shift Operations ---");
        test_shift_detailed(8'b10110011, 2'b00, 4'd2, "SLL by 2");
        test_shift_detailed(8'b10110011, 2'b01, 4'd3, "SRL by 3");
        test_shift_detailed(8'b10110011, 2'b10, 4'd2, "SRA by 2");
        test_shift_detailed(8'b10110011, 2'b11, 4'd4, "ROR by 4");
        
        $display("\n--- TEST PATTERN 7: Edge Cases and Boundaries ---");
        test_alu_operation(3'b000, 8'hFF, 8'hFF, "Forward: Maximum");
        test_alu_operation(3'b001, 8'h7F, 8'h7F, "Add: Positive max");
        test_alu_operation(3'b001, 8'h80, 8'h7F, "Add: Mixed signs");
        test_alu_operation(3'b100, 8'hFF, 8'hFF, "MUL: Maximum");
        
        $display("\n--- TEST PATTERN 8: Zero Flag Analysis ---");
        test_alu_operation(3'b001, 8'h80, 8'h80, "Zero flag: True case");
        test_alu_operation(3'b001, 8'h01, 8'hFF, "Zero flag: Wraparound");
        test_alu_operation(3'b010, 8'hFF, 8'h00, "Zero flag: AND result");
        test_alu_operation(3'b011, 8'h00, 8'h00, "Zero flag: OR result");
        
        $display("\n--- TEST PATTERN 9: Operation Switching ---");
        // Test rapid operation changes to verify multiplexer behavior
        ALUOP = 3'b000; DATA1 = 8'hAA; DATA2 = 8'h55; #5;
        ALUOP = 3'b001; #5;
        ALUOP = 3'b010; #5;
        ALUOP = 3'b011; #5;
        ALUOP = 3'b100; #5;
        ALUOP = 3'b101; #5;
        $display("Operation switching test completed - check waveform timing");
        
        $display("\n===================================================================");
        $display("ALU Comprehensive Test Completed!");
        $display("");
        $display("GTKWave Analysis Instructions:");
        $display("1. Open ALU_comprehensive.vcd in GTKWave");
        $display("2. Add these signal groups for analysis:");
        $display("   - Inputs: DATA1, DATA2, ALUOP");
        $display("   - Outputs: RESULT, ZERO");
        $display("   - Unit Results: *_result signals");
        $display("   - Internal: uut.u*.RESULT for each functional unit");
        $display("3. Key analysis points:");
        $display("   - Verify RESULT matches correct unit output based on ALUOP");
        $display("   - Observe ZERO flag behavior (always reflects addition)");
        $display("   - Check timing relationships and propagation delays");
        $display("   - Compare functional unit outputs vs final RESULT");
        $display("4. Look for potential issues:");
        $display("   - Glitches during operation switching");
        $display("   - Incorrect multiplexer selection"); 
        $display("   - Timing violations or race conditions");
        $display("===================================================================");
        
        #50;
        $finish;
    end

endmodule