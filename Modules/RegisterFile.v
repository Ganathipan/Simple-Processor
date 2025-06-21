// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2024-06-09
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// RegisterFile.v - Register File module
// Purpose: Implements an 8-register file with read and write capabilities for the processor datapath.
// -----------------------------------------------------------------------------

module reg_file(
    input [7:0] INDATA,             // Data to write to register file
    input [2:0] INADDRESS,          // Address of register to write
    input [2:0] OUT1ADDRESS,        // Address of register to read (port 1)
    input [2:0] OUT2ADDRESS,        // Address of register to read (port 2)
    output reg [7:0] OUT1DATA,      // Data output from register (port 1)
    output reg [7:0] OUT2DATA,      // Data output from register (port 2)
    input CLK,                      // Clock signal
    input RESET,                    // Reset signal (active high)
    input  WRITE                    // Write enable signal
    );

    reg [7:0] reg_array [0:7]; // 8 registers, 8 bits each

    // Combinational read: output data from selected registers
    always @(*) begin
        OUT1DATA <= #2 reg_array[OUT1ADDRESS];  // Output data from register OUT1ADDRESS (port 1)
        OUT2DATA <= #2 reg_array[OUT2ADDRESS];  // Output data from register OUT2ADDRESS (port 2)
    end

    // Sequential write: on positive clock edge, write data to register if enabled and not in reset
    always @(posedge CLK) begin
        if(WRITE == 1'b1  &&  RESET == 1'b0) begin 
            reg_array[INADDRESS] <= #1 INDATA; // Write data to register at INADDRESS
        end
    end

    // Synchronous reset: clear all registers to zero on reset
    integer counter;             // Loop variable for reset
    always @(posedge CLK) begin
        if(RESET == 1'b1) begin
            for(counter = 0; counter < 8; counter = counter + 1) begin
                reg_array[counter] <= #1 8'b00000000; // Clear register to zero
            end
        end
    end
endmodule