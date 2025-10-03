// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// RegisterFile.v - Processor Register File Implementation  
// Purpose: Implements 8-register storage array with dual-port read and single-port
//          write capabilities. Provides high-speed register access for the processor
//          datapath with asynchronous reads and synchronous writes.
// -----------------------------------------------------------------------------

// Register File - Central register storage for the processor
// Contains 8 general-purpose registers (R0-R7) with dual read ports for
// supporting two-operand instructions and single write port for results
module reg_file(
    input [7:0] INDATA,             // 8-bit data to be written to register
    input [2:0] INADDRESS,          // 3-bit destination register address (0-7)
    input [2:0] OUT1ADDRESS,        // 3-bit address for first read port
    input [2:0] OUT2ADDRESS,        // 3-bit address for second read port  
    output reg [7:0] OUT1DATA,      // 8-bit data from first read port
    output reg [7:0] OUT2DATA,      // 8-bit data from second read port
    input CLK,                      // System clock for synchronous writes
    input RESET,                    // Reset signal to clear all registers
    input  WRITE                    // Write enable signal
);

    // Register storage array - 8 registers × 8 bits each
    reg [7:0] reg_array [0:7]; 

    // Asynchronous read logic - provides immediate access to register contents
    // Supports dual-port reading for two-operand instructions (e.g., ADD R1, R2, R3)
    always @(*) begin
        OUT1DATA <= #2 reg_array[OUT1ADDRESS];  // Read port 1 with 2ns access delay
        OUT2DATA <= #2 reg_array[OUT2ADDRESS];  // Read port 2 with 2ns access delay
    end

    // Synchronous write logic - updates register on clock edge when enabled
    always @(posedge CLK) begin
        if(WRITE == 1'b1  &&  RESET == 1'b0) begin 
            reg_array[INADDRESS] <= #1 INDATA;  // Write data with 1ns setup delay
        end
    end

    // Register reset logic - clears all registers to zero on reset
    integer counter;             
    always @(posedge CLK) begin
        if(RESET == 1'b1) begin
            // Clear all 8 registers to initial state (0x00)
            for(counter = 0; counter < 8; counter = counter + 1) begin
                reg_array[counter] <= #1 8'b00000000;
            end
        end
    end
endmodule