// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// simpleComputer.v - Complete Computer System Integration
// Purpose: Top-level module integrating CPU, caches, and main memory into a
//          complete computer system. Provides proper bus interconnections and
//          signal routing for full system operation and testing.
// -----------------------------------------------------------------------------

// System Module - Complete Computer System  
// Integrates all major components: CPU, instruction cache, data cache,
// instruction memory, and data memory with proper bus protocols
module system(
    input CLK,                      // System clock for all components
    input RESET                     // System reset signal
);

    // Data Memory Hierarchy Bus Signals
    // CPU ↔ Data Cache ↔ Data Memory interconnections
    wire READ_DATA_MEM2CAC;         // Data cache to memory read enable
    wire WRITE_DATA_MEM2CAC;        // Data cache to memory write enable  
    wire BUSYWAIT_MEM2CAC;          // Data memory busy signal to cache
    wire [5:0] MEM_ADDRESS_MEM2CAC; // Block address from cache to memory
    wire [31:0] INDATA_MEM2CAC;     // Data from memory to cache
    wire [31:0] OUTDATA_MEM2CAC;    // Data from cache to memory

    // Instruction Memory Hierarchy Bus Signals  
    // CPU ↔ Instruction Cache ↔ Instruction Memory interconnections
    wire INST_MEM_READ;             // Instruction cache to memory read enable
    wire INST_MEM_BUSYWAIT;         // Instruction memory busy signal to cache
    wire [127:0] INST_MEM_DATA;     // Instruction block from memory to cache
    wire [5:0] INST_MEM_ADDRESS;    // Block address from cache to memory

    // CPU Instantiation - Core processor with cache interfaces
    CPU u_cpu(
        .CLK(CLK),                                      // System clock
        .RESET(RESET),                                  // System reset
        // Data Cache Interface
        .READ_DATA_MEM2CAC(READ_DATA_MEM2CAC),         // Data read request
        .WRITE_DATA_MEM2CAC(WRITE_DATA_MEM2CAC),       // Data write request
        .MEM_ADDRESS_MEM2CAC(MEM_ADDRESS_MEM2CAC),     // Data memory address
        .OUTDATA_MEM2CAC(OUTDATA_MEM2CAC),             // Data to memory
        .INDATA_MEM2CAC(INDATA_MEM2CAC),               // Data from memory
        .BUSYWAIT_MEM2CAC(BUSYWAIT_MEM2CAC),           // Data memory busy
        // Instruction Cache Interface  
        .INST_MEM_READ(INST_MEM_READ),                 // Instruction read request
        .INST_MEM_ADDRESS(INST_MEM_ADDRESS),           // Instruction memory address
        .INST_MEM_DATA(INST_MEM_DATA),                 // Instructions from memory
        .INST_MEM_BUSYWAIT(INST_MEM_BUSYWAIT)          // Instruction memory busy
    );

    // Data Memory Instantiation - Main memory for data storage
    data_memory u_data_mem(
        .clock(CLK),                                    // System clock
        .reset(RESET),                                  // Memory reset
        .read(READ_DATA_MEM2CAC),                       // Read enable from cache
        .write(WRITE_DATA_MEM2CAC),                     // Write enable from cache
        .address(MEM_ADDRESS_MEM2CAC),                  // Block address from cache
        .writedata(OUTDATA_MEM2CAC),                    // Write data from cache
        .readdata(INDATA_MEM2CAC),                      // Read data to cache
        .busywait(BUSYWAIT_MEM2CAC)                     // Memory busy to cache
    );

    // Instruction Memory Instantiation - Main memory for instruction storage
    instruction_memory u_inst_mem(
        .clock(CLK),                                    // System clock  
        .read(INST_MEM_READ),                           // Read enable from cache
        .address(INST_MEM_ADDRESS),                     // Block address from cache
        .readinst(INST_MEM_DATA),                       // Instruction block to cache
        .busywait(INST_MEM_BUSYWAIT)                    // Memory busy to cache
    );
endmodule