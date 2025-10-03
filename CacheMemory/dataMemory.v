// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// Original Author: Isuru Nawinne (30/05/2020)
// -----------------------------------------------------------------------------
// dataMemory.v - Main Data Memory Implementation
// Purpose: Implements main memory for data storage with realistic DRAM-like
//          timing characteristics. Provides block-based data transfers (4 bytes)
//          with proper handshaking protocols for cache interface.
// -----------------------------------------------------------------------------

// Data Memory Module - Main memory simulation with realistic timing
// 256×8-bit memory organized as 64 blocks of 4 bytes each
// Provides 40ns access latency to simulate realistic DRAM characteristics
module data_memory(
	input           clock,          // System clock
    input           reset,          // Memory reset signal
    input           read,           // Read enable from cache
    input           write,          // Write enable from cache  
    input[5:0]      address,        // 6-bit block address (64 possible blocks)
    input[31:0]     writedata,      // 32-bit block data for writes
    output reg [31:0] readdata,     // 32-bit block data for reads
    output reg      busywait        // Memory busy signal to cache
);

integer i;

//Declare memory array 256x8-bits 
reg [7:0] memory_array [255:0];

//Detecting an incoming memory access
reg readaccess, writeaccess;
always @(read, write)
begin
	busywait = (read || write)? 1 : 0;
	readaccess = (read && !write)? 1 : 0;
	writeaccess = (!read && write)? 1 : 0;
end

//Reading & writing
always @(posedge clock)
begin
	if(readaccess)
	begin
		readdata[7:0]   = #40 memory_array[{address,2'b00}];
		readdata[15:8]  = #40 memory_array[{address,2'b01}];
		readdata[23:16] = #40 memory_array[{address,2'b10}];
		readdata[31:24] = #40 memory_array[{address,2'b11}];
		busywait = 0;
		readaccess = 0;
	end
	if(writeaccess)
	begin
		memory_array[{address,2'b00}] = #40 writedata[7:0];
		memory_array[{address,2'b01}] = #40 writedata[15:8];
		memory_array[{address,2'b10}] = #40 writedata[23:16];
		memory_array[{address,2'b11}] = #40 writedata[31:24];
		busywait = 0;
		writeaccess = 0;
	end
end

//Reset memory
always @(posedge reset)
begin
    if (reset)
    begin
        for (i=0;i<256; i=i+1)
            memory_array[i] = 0;
        
        busywait = 0;
		readaccess = 0;
		writeaccess = 0;
    end
end

endmodule