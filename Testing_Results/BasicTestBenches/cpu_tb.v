// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// cpu_tb.v - Comprehensive CPU System Testbench
// Purpose: Complete system-level testbench for processor verification and
//          performance analysis. Provides instruction memory loading, clock
//          generation, reset control, and comprehensive waveform monitoring
//          for debugging and validation of the complete processor system.
// -----------------------------------------------------------------------------

// CPU Testbench - System-level verification environment
// Integrates CPU with instruction memory simulation and provides comprehensive
// monitoring capabilities for register contents, instruction execution, and timing analysis
module cpu_tb;

    // Testbench Control Signals
    reg CLK, RESET;                 // Clock and reset generation  
    wire [31:0] PC;                 // Program counter output from CPU
    reg [31:0] INSTRUCTION;         // Current instruction being executed
    reg [7:0] instr_mem [0:1023];   // 1KB instruction memory array for simulation
    integer i;                      // Loop counter for test cycles

    // CPU Under Test Instantiation
    // Note: This interface may need updating based on actual CPU module ports
    CPU mycpu (
        .PC_OUT(PC),                // Program counter output for monitoring
        .INSTRUCTION(INSTRUCTION),  // Instruction input (simulated fetch)
        .CLK(CLK),                  // System clock
        .RESET(RESET)               // System reset
    );

    // Clock Generation - 12 time unit period (6ns high, 6ns low)
    // Provides stable clock signal for synchronous CPU operation
    always #6 CLK = ~CLK;

    // Instruction Fetch Simulation 
    // Simulates instruction memory by fetching 32-bit instructions based on PC
    always @(PC) begin
        // Fetch 4 consecutive bytes to form 32-bit instruction (little-endian)
        INSTRUCTION <= #2 {
            instr_mem[PC + 3],      // MSB (bits 31-24)
            instr_mem[PC + 2],      // Bits 23-16  
            instr_mem[PC + 1],      // Bits 15-8
            instr_mem[PC + 0]       // LSB (bits 7-0)
        };
    end        

    // Enhanced instruction decode task for detailed analysis
    task display_instruction_info;
        input [31:0] instr;
        input [31:0] pc_val;
        input integer cycle_num;
        reg [7:0] opcode, rd, rs1, rs2_imm;
        reg [79:0] instr_name;
        begin
            // Extract instruction fields
            opcode = instr[7:0];
            rd = instr[15:8];
            rs1 = instr[23:16]; 
            rs2_imm = instr[31:24];
            
            // Decode instruction type
            case (opcode)
                8'b00000000: instr_name = "LOADI";
                8'b00000001: instr_name = "MOV";
                8'b00000010: instr_name = "ADD";
                8'b00000011: instr_name = "SUB";
                8'b00000100: instr_name = "AND";
                8'b00000101: instr_name = "OR";
                8'b00000110: instr_name = "J";
                8'b00000111: instr_name = "BEQ";
                8'b00001000: instr_name = "LWD";
                8'b00001001: instr_name = "LWI";
                8'b00001010: instr_name = "SWD";
                8'b00001011: instr_name = "SWI";
                8'b00001100: instr_name = "MUL";
                8'b00001101: instr_name = "SHIFT";
                8'b00001110: instr_name = "BNE";
                default: instr_name = "UNKNOWN";
            endcase
            
            $display("Cycle %2d: PC=%3d | %s | Fields: RD=%0d, RS1=%0d, RS2/IMM=0x%02h", 
                     cycle_num, pc_val, instr_name, rd, rs1, rs2_imm);
            $display("          Binary: %b_%b_%b_%b", 
                     instr[31:24], instr[23:16], instr[15:8], instr[7:0]);
        end
    endtask
    
    // Register monitoring task
    task display_register_state;
        integer j;
        begin
            $display("Register State:");
            for (j = 0; j < 8; j = j + 1) begin
                $display("  R%0d = 0x%02h (%3d)", j, 
                         mycpu.u_regfile.reg_array[j], 
                         mycpu.u_regfile.reg_array[j]);
            end
        end
    endtask
    
    // Enhanced main test sequence
    initial begin
        $display("===================================================================");
        $display("Enhanced CPU System Testbench - Comprehensive Analysis");
        $display("===================================================================");
        
        // Create sample test program if none exists
        $display("Initializing test program...");
        
        // Sample program: Basic arithmetic and control flow
        // LOADI R1, #10        -> 0x0A000001_00000000
        {instr_mem[3], instr_mem[2], instr_mem[1], instr_mem[0]} = 32'h0A000100;
        // LOADI R2, #5         -> 0x05000002_00000000  
        {instr_mem[7], instr_mem[6], instr_mem[5], instr_mem[4]} = 32'h05000200;
        // ADD R3, R1, R2       -> R1=R1, R2=R2, R3=RD -> 0x00020103_00000010
        {instr_mem[11], instr_mem[10], instr_mem[9], instr_mem[8]} = 32'h00010302;
        // MUL R4, R3, R2       -> 0x00020304_00001100
        {instr_mem[15], instr_mem[14], instr_mem[13], instr_mem[12]} = 32'h00020304;  // Need to fix: should be 0x0002030C
        // SLL R5, R4, #2       -> Shift left by 2
        {instr_mem[19], instr_mem[18], instr_mem[17], instr_mem[16]} = 32'h02040500; // SLL format needs correction
        // MOV R6, R5           -> 0x00000506_00000001
        {instr_mem[23], instr_mem[22], instr_mem[21], instr_mem[20]} = 32'h00050601;
        // J #0                 -> Jump to start: 0x00000000_00000110
        {instr_mem[27], instr_mem[26], instr_mem[25], instr_mem[24]} = 32'h00000006;
        
        // Try to load from file if it exists, otherwise use sample program
        $readmemb("../SimpleComputer/instr_mem.mem", instr_mem);
        $display("Program loaded (file or sample program)");

        // Enhanced Waveform Generation Setup  
        $dumpfile("Testing_Results/gtkwave_files/cpu_test.vcd");
        $dumpvars(0, cpu_tb);
        
        // Detailed CPU internal monitoring
        $dumpvars(1, mycpu.PC_OUT);                    // Program Counter
        $dumpvars(1, mycpu.INSTRUCTION);               // Current Instruction
        $dumpvars(1, mycpu.u_control.ALUOP);          // ALU Operation
        $dumpvars(1, mycpu.u_control.WRITE_ENABLE);   // Register Write
        $dumpvars(1, mycpu.u_control.BRANCH_CONTROL); // Branch Control
        $dumpvars(1, mycpu.u_alu.RESULT);             // ALU Result
        $dumpvars(1, mycpu.u_alu.ZERO);               // Zero Flag
        $dumpvars(1, mycpu.OPERAND1);                 // ALU Input 1
        $dumpvars(1, mycpu.OPERAND2);                 // ALU Input 2
        $dumpvars(1, mycpu.ALU_IN_DATA1);             // ALU Actual Input 1
        $dumpvars(1, mycpu.ALU_IN_DATA2);             // ALU Actual Input 2
        
        // Monitor all registers individually
        $dumpvars(1, mycpu.u_regfile.reg_array[0]);   // R0
        $dumpvars(1, mycpu.u_regfile.reg_array[1]);   // R1  
        $dumpvars(1, mycpu.u_regfile.reg_array[2]);   // R2
        $dumpvars(1, mycpu.u_regfile.reg_array[3]);   // R3
        $dumpvars(1, mycpu.u_regfile.reg_array[4]);   // R4
        $dumpvars(1, mycpu.u_regfile.reg_array[5]);   // R5
        $dumpvars(1, mycpu.u_regfile.reg_array[6]);   // R6
        $dumpvars(1, mycpu.u_regfile.reg_array[7]);   // R7

        // System Initialization
        CLK = 0;
        RESET = 1;
        #8;
        @(posedge CLK);
        RESET = 0;
        
        $display("\n=== Starting CPU Execution Analysis ===");
        display_instruction_info(INSTRUCTION, PC, 0);
        
        // Enhanced execution monitoring with detailed analysis
        for (i = 1; i <= 25; i = i + 1) begin
            @(posedge CLK);
            
            // Display detailed instruction and state information
            display_instruction_info(INSTRUCTION, PC, i);
            
            // Show ALU operation details when relevant
            if (mycpu.u_control.WRITE_ENABLE) begin
                $display("          ALU: OP=%b, IN1=0x%02h, IN2=0x%02h, OUT=0x%02h, ZERO=%b",
                         mycpu.u_control.ALUOP, mycpu.ALU_IN_DATA1, mycpu.ALU_IN_DATA2,
                         mycpu.u_alu.RESULT, mycpu.u_alu.ZERO);
            end
            
            // Show register state every 5 cycles or when significant changes occur
            if ((i % 5) == 0 || mycpu.u_control.WRITE_ENABLE) begin
                display_register_state();
                $display("");
            end
            
            // Detect infinite loops or jumps
            if (i > 10 && PC == 0) begin
                $display(">>> LOOP DETECTED: Program jumped back to start");
                break;
            end
        end

        $display("\n=== Final System State ===");
        display_register_state();
        
        $display("\n===================================================================");
        $display("CPU Comprehensive Test Completed!");
        $display("");
        $display("GTKWave Analysis Guide:");
        $display("1. Open cpu_comprehensive.vcd in GTKWave");
        $display("2. Recommended signal groups:");
        $display("   Group 1 - Control Flow:");
        $display("     - cpu_tb.CLK, cpu_tb.RESET");
        $display("     - cpu_tb.PC, cpu_tb.INSTRUCTION");
        $display("     - cpu_tb.mycpu.u_control.BRANCH_CONTROL");
        $display("   Group 2 - ALU Operations:");
        $display("     - cpu_tb.mycpu.u_control.ALUOP");
        $display("     - cpu_tb.mycpu.ALU_IN_DATA1, ALU_IN_DATA2");
        $display("     - cpu_tb.mycpu.u_alu.RESULT, ZERO");
        $display("   Group 3 - Register File:");
        $display("     - cpu_tb.mycpu.u_control.WRITE_ENABLE");
        $display("     - cpu_tb.mycpu.u_regfile.reg_array[0:7]");
        $display("   Group 4 - Datapath:");
        $display("     - cpu_tb.mycpu.OPERAND1, OPERAND2");
        $display("     - cpu_tb.mycpu.REG_INDATA");
        $display("3. Analysis points:");
        $display("   - Verify instruction decode and execution");
        $display("   - Check ALU operation selection and results");
        $display("   - Monitor register file updates");
        $display("   - Analyze control flow and branching");
        $display("4. Look for timing issues and proper synchronization");
        $display("===================================================================");
        
        #50;
        $finish;
    end
endmodule
