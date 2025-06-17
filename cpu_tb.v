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

    // Clock generation (period = 8 time units)
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
        $display("->    Cycle %0d: PC = %0d, Instruction = %b", i, PC, INSTRUCTION);
    end

    initial begin
        // Load instruction memory from file
        $readmemb("instr_mem.mem", instr_mem);

        // Optional: Display initial memory (commented)
        /*
        $display("Instruction Memory Contents (First 32 Bytes):");
        for (i = 0; i < 32; i = i + 1) begin
            $display("addr[%0d] = %b", i, instr_mem[i]);
        end
        */

        // Initialize waveform dump
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);
        /*
        $dumpvars(1, cpu_tb.mycpu.u_regfile.r0);
        $dumpvars(1, cpu_tb.mycpu.u_regfile.r1);
        $dumpvars(1, cpu_tb.mycpu.u_regfile.r2);
        $dumpvars(1, cpu_tb.mycpu.u_regfile.r3);
        $dumpvars(1, cpu_tb.mycpu.u_regfile.r4);
        $dumpvars(1, cpu_tb.mycpu.u_regfile.r5);
        $dumpvars(1, cpu_tb.mycpu.u_regfile.r6);
        $dumpvars(1, cpu_tb.mycpu.u_regfile.r7);
        */

        // Initialize signals
        CLK = 0;
        RESET = 1;
        #8; // Wait 8 time units for RESET to propagate
        @(posedge CLK);  // Sync with clock
        RESET = 0;

        // Run for 4 cycles
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge CLK);
        end

        #10 $finish;
    end

endmodule
