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

    // Main Test Sequence
    initial begin
        // Test Environment Setup
        $display("=== Starting CPU System Testbench ===");
        
        // Load instruction memory from assembled program file
        $readmemb("instr_mem.mem", instr_mem);
        $display("Loaded instruction memory from instr_mem.mem");

        // Waveform Generation Setup for GTKWave analysis
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);           // Dump all testbench signals
        
        // Monitor individual register contents for debugging
        $dumpvars(1, cpu_tb.mycpu.u_regfile.reg_array[0]);  // Register R0
        $dumpvars(1, cpu_tb.mycpu.u_regfile.reg_array[1]);  // Register R1
        $dumpvars(1, cpu_tb.mycpu.u_regfile.reg_array[2]);  // Register R2
        $dumpvars(1, cpu_tb.mycpu.u_regfile.reg_array[3]);  // Register R3
        $dumpvars(1, cpu_tb.mycpu.u_regfile.reg_array[4]);  // Register R4
        $dumpvars(1, cpu_tb.mycpu.u_regfile.reg_array[5]);  // Register R5
        $dumpvars(1, cpu_tb.mycpu.u_regfile.reg_array[6]);  // Register R6
        $dumpvars(1, cpu_tb.mycpu.u_regfile.reg_array[7]);  // Register R7

        // System Initialization
        CLK = 0;                        // Initialize clock to 0
        RESET = 1;                      // Assert reset
        #8;                             // Hold reset for 8 time units
        @(posedge CLK);                 // Synchronize with clock edge
        RESET = 0;                      // Release reset
        
        // Display initial state
        $display("Reset released. Starting program execution...");
        $display("->    Cycle %0d: PC = %0d, Instruction = %b_%b_%b_%b", 
                 0, PC, INSTRUCTION[31:24], INSTRUCTION[23:16], INSTRUCTION[15:8], INSTRUCTION[7:0]);

        // Execution Monitoring Loop
        // Run for 30 clock cycles and display execution progress
        for (i = 1; i <= 30; i = i + 1) begin
            @(posedge CLK);             // Wait for next clock edge
            $display("->    Cycle %0d: PC = %0d, Instruction = %b_%b_%b_%b", 
                     i, PC, INSTRUCTION[31:24], INSTRUCTION[23:16], INSTRUCTION[15:8], INSTRUCTION[7:0]);
        end

        // Test Completion
        $display("=== CPU System Test Completed ===");
        #10 $finish;                    // End simulation after 10 more time units
    end
endmodule
