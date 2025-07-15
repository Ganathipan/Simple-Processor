// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// Description: Testbench for CO224 Lab 6 instruction cache integration. This file simulates the CPU system,
// loads instructions from instruction memory, generates the clock and reset signals, and dumps waveforms 
// to verify correct operation including instruction cache and data cache behavior.

module cpu_tb;

    reg CLK, RESET;
    integer i;

    // Instantiate the system (CPU + caches + memories)
    system mysystem (
        .CLK(CLK),
        .RESET(RESET)
    );

    // Clock generation (period = 8 time units)
    always #4 CLK = ~CLK;

    initial begin
        // Initialize waveform dump
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);

        for (i = 0; i < 8; i = i + 1) begin
            // Dump register file
            $dumpvars(1, cpu_tb.mysystem.u_cpu.u_regfile.reg_array[i]); 

            // Dump data cache blocks
            $dumpvars(1, cpu_tb.mysystem.u_cpu.u_data_cache.data_blocks[i]);

            // Dump data memory
            $dumpvars(1, cpu_tb.mysystem.u_data_mem.memory_array[i]);

            // Dump instruction cache blocks
            $dumpvars(1, cpu_tb.mysystem.u_cpu.u_inst_cache.data_array[i]);

            // Dump data memory
            $dumpvars(1, cpu_tb.mysystem.u_inst_mem.memory_array[i]);
        end

        // Dump PC and instruction
        $dumpvars(1, cpu_tb.mysystem.u_cpu.PC_OUT);
        $dumpvars(1, cpu_tb.mysystem.u_cpu.INSTRUCTION);

        // Initialize signals
        CLK = 0;
        RESET = 1;

        #15; // Wait for reset propagation
        RESET = 0;

        // Run simulation
        $display("------ CPU Simulation Start ------");

        // Observe clock cycles
        repeat (200) begin
            @(posedge CLK);
            $display("Cycle: %0d | PC = %h | Instruction = %h", $time / 8, mysystem.u_cpu.PC_OUT, mysystem.u_cpu.INSTRUCTION);
        end

        $display("------ CPU Simulation Complete ------");

        #10 $finish;
    end
endmodule
