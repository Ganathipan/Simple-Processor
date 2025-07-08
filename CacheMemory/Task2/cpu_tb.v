// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// Description: Testbench for the CO224 Lab 5 Task 5 processor. This file simulates the CPU, loads instructions from memory, generates the clock and reset signals, and dumps waveforms for analysis. It is used to verify the correct operation of the processor and observe register/memory behavior during execution.

module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    reg [31:0] INSTRUCTION;
    reg [7:0] instr_mem [0:1023];  // 1KB instruction memory
    integer i;

    // Instantiate the CPU
    CPU mycpu (
        .PC_OUT(PC),
        .INSTRUCTION(INSTRUCTION),
        .CLK(CLK),
        .RESET(RESET)
    );

    // Clock generation (period = 10 time units)
    always #4 CLK = ~CLK;

    // Instruction fetch on PC change
    always @(PC) begin
        // Instruction memory should be word-addressable in steps of 4
        INSTRUCTION <= #2 {
            instr_mem[PC + 0],
            instr_mem[PC + 1],
            instr_mem[PC + 2],
            instr_mem[PC + 3]
        };
    end        

    initial begin
        // Load instruction memory from file
        $readmemb("instr_mem_cache.mem", instr_mem);

        // Initialize waveform dump
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);

        for (i = 0; i < 8; i = i + 1) 
            $dumpvars(1, cpu_tb.mycpu.u_regfile.reg_array[i]);

        for (i = 0; i < 8; i = i+1)
            $dumpvars(2, cpu_tb.mycpu.u_data_cache.data_blocks[i]);

        // Initialize signals
        CLK = 0;
        RESET = 1;
        #10;  // Sync with clock
        RESET = 0;
        #10;  // Sync with clock

        $display("->    Cycle %0d: PC = %0d, Instruction = %b %b %b %b", i, PC, INSTRUCTION[31:24], INSTRUCTION[23:16], INSTRUCTION[15:8], INSTRUCTION[7:0]);

        // Run for 20 cycles and display PC and instruction at each cycle
        for (i = 0; i < 30; i = i + 1) begin
            @(posedge CLK);
            $display("->    Cycle %0d: PC = %0d, Instruction = %b %b %b %b", i, PC, INSTRUCTION[31:24], INSTRUCTION[23:16], INSTRUCTION[15:8], INSTRUCTION[7:0]);
        end

        #10 $finish;
    end
endmodule
