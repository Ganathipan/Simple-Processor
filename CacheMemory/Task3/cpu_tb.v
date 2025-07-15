// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// Description: Testbench for the CO224 Lab 5 Task 5 processor. This file simulates the CPU, loads instructions from memory, generates the clock and reset signals, and dumps waveforms for analysis. It is used to verify the correct operation of the processor and observe register/memory behavior during execution.

module cpu_tb;

    reg CLK, RESET;
    integer i;

    // Instantiate the CPU
    system mysystem (
        .CLK(CLK),
        .RESET(RESET)
    );

    // Clock generation (period = 10 time units)
    always #4 CLK = ~CLK;    

    initial begin
        // Initialize waveform dump
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);

        for (i = 0; i < 8; i = i + 1) 
            $dumpvars(1, cpu_tb.mysystem.u_cpu.u_regfile.reg_array[i]);

        for (i = 0; i < 8; i = i+1)
            $dumpvars(2, cpu_tb.mysystem.u_cpu.u_data_cache.data_blocks[i]);

        for (i = 0; i < 8; i = i+1)
            $dumpvars(3, cpu_tb.mysystem.u_cpu.u_data_mem.memory_array[i]);

        for (i = 0; i < 8; i = i+1)
            $dumpvars(4, cpu_tb.mysystem.u_cpu.u_instruction_cache.data_blocks[i]);
        
        for (i = 0; i < 8; i = i+1)
            $dumpvars(5, cpu_tb.mysystem.u_cpu.u_instruction_mem.memory_array[i]);

        i = 0; // Resetting counter

        // Initialize signals
        CLK = 0;
        RESET = 1;
        #10;  // Sync with clock
        RESET = 0;
        #10;  // Sync with clock


        // Run for 20 cycles and display PC and instruction at each cycle
        for (i = 0; i < 126; i = i + 1) begin
            @(posedge CLK);
            $display("->    Cycle %0d", i);
        end

        #10 $finish;
    end
endmodule
