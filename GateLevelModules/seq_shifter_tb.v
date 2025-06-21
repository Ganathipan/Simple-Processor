// Authors: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, University of Peradeniya (UOP)

module gate_level_seq_shifter_tb;

    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg [1:0] ctrl;
    reg [2:0] shift_amt;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;
    wire done;

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

    // Task to perform a test
    task run_test;
        input [1:0] t_ctrl;
        input [2:0] t_amt;
        input [7:0] t_data;
        begin
            @(negedge clk);
            ctrl      = t_ctrl;
            shift_amt = t_amt;
            data_in   = t_data;
            start     = 1;
            @(negedge clk);
            start     = 0;

            // Wait for done
            wait(done == 1);
            @(negedge clk);
            $display("CTRL = %b, SHIFT_AMT = %d, IN = %b => OUT = %b", ctrl, shift_amt, data_in, data_out);
        end
    endtask

    // Test sequence
    initial begin
        $display("Starting gate-level universal shifter testbench...");
        $dumpfile("GateLevelModues/seq_shifter.vcd");  // VCD output file
        $dumpvars(0, gate_level_seq_shifter_tb);  // Dump all signals recursively
        clk = 0;
        rst = 1;
        start = 0;
        ctrl = 2'b00;
        shift_amt = 3'b000;
        data_in = 8'h00;

        #20;
        rst = 0;

        // Run different shift tests
        run_test(2'b00, 3'd1, 8'b10110011); // Logical Left Shift by 1
        run_test(2'b01, 3'd2, 8'b10110011); // Logical Right Shift by 2
        run_test(2'b10, 3'd3, 8'b10110011); // Arithmetic Right Shift by 3
        run_test(2'b11, 3'd4, 8'b10110011); // Rotate Right by 4

        $display("Testbench complete.");
        $finish;
    end

endmodule
