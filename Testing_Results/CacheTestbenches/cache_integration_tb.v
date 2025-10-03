// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// cache_integration_tb.v - Integrated Cache System Testbench
// Purpose: Tests both instruction and data caches working together in a
//          unified system scenario. Verifies cache interactions, system
//          performance, and realistic processor memory access patterns.
// -----------------------------------------------------------------------------

`timescale 1ns/100ps

// Integrated Cache System Testbench
// Tests instruction and data caches in a coordinated system environment
module cache_integration_tb;

    // System-wide signals
    reg clock, reset;
    
    // CPU-side instruction cache interface
    reg [31:0] i_address;
    wire [31:0] i_readdata;
    wire i_busywait;
    
    // CPU-side data cache interface  
    reg d_read, d_write;
    reg [7:0] d_address;
    reg [7:0] d_writedata;
    wire [7:0] d_readdata;
    wire d_busywait;
    
    // Instruction memory interface
    wire i_mem_read;
    wire [5:0] i_mem_address;
    wire [127:0] i_mem_readdata;
    wire i_mem_busywait;
    
    // Data memory interface
    wire d_mem_read, d_mem_write;
    wire [5:0] d_mem_address;
    wire [31:0] d_mem_writedata, d_mem_readdata;
    wire d_mem_busywait;
    
    // Test control and monitoring
    integer test_count, total_cycles;
    integer i_cache_accesses, d_cache_accesses;
    integer i_hits, i_misses, d_hits, d_misses;
    integer concurrent_operations;
    
    // Instantiate instruction cache and memory
    inst_cache instruction_cache (
        .clock(clock),
        .reset(reset),
        .address(i_address),
        .readdata(i_readdata),
        .busywait(i_busywait),
        .mem_read(i_mem_read),
        .mem_address(i_mem_address),
        .mem_readdata(i_mem_readdata),
        .mem_busywait(i_mem_busywait)
    );
    
    instruction_memory instruction_mem (
        .clock(clock),
        .read(i_mem_read),
        .address(i_mem_address),
        .readinst(i_mem_readdata),
        .busywait(i_mem_busywait)
    );
    
    // Instantiate data cache and memory
    data_cache data_cache_inst (
        .clk(clock),
        .reset(reset),
        .read(d_read),
        .write(d_write),
        .address(d_address),
        .writedata(d_writedata),
        .readdata(d_readdata),
        .busywait(d_busywait),
        .mem_read(d_mem_read),
        .mem_write(d_mem_write),
        .mem_address(d_mem_address),
        .mem_writedata(d_mem_writedata),
        .mem_readdata(d_mem_readdata),
        .mem_busywait(d_mem_busywait)
    );
    
    data_memory data_mem (
        .clock(clock),
        .reset(reset),
        .read(d_mem_read),
        .write(d_mem_write),
        .address(d_mem_address),
        .writedata(d_mem_writedata),
        .readdata(d_mem_readdata),
        .busywait(d_mem_busywait)
    );
    
    // Clock generation
    always #5 clock = ~clock;
    
    // Task for instruction fetch operation
    task fetch_instruction;
        input [31:0] pc_address;
        input [127:0] test_name;
        integer fetch_cycles;
        begin
            i_cache_accesses = i_cache_accesses + 1;
            $display("IFETCH: PC=0x%08h (%s)", pc_address, test_name);
            
            i_address = pc_address;
            fetch_cycles = 0;
            
            while (i_busywait) begin
                @(posedge clock);
                fetch_cycles = fetch_cycles + 1;
                total_cycles = total_cycles + 1;
            end
            @(posedge clock);
            fetch_cycles = fetch_cycles + 1;
            total_cycles = total_cycles + 1;
            
            if (fetch_cycles <= 2) begin
                i_hits = i_hits + 1;
                $display("  I-Cache HIT: Inst=0x%08h (%0d cycles)", i_readdata, fetch_cycles);
            end else begin
                i_misses = i_misses + 1;
                $display("  I-Cache MISS: Inst=0x%08h (%0d cycles)", i_readdata, fetch_cycles);
            end
        end
    endtask
    
    // Task for data memory operation
    task access_data_memory;
        input is_read;
        input [7:0] data_addr;
        input [7:0] write_val;
        input [127:0] test_name;
        integer access_cycles;
        reg [7:0] read_result;
        begin
            d_cache_accesses = d_cache_accesses + 1;
            if (is_read) begin
                $display("DREAD: Addr=0x%02h (%s)", data_addr, test_name);
            end else begin
                $display("DWRITE: Addr=0x%02h, Data=0x%02h (%s)", data_addr, write_val, test_name);
            end
            
            @(negedge clock);
            d_address = data_addr;
            if (is_read) begin
                d_read = 1;
                d_write = 0;
                d_writedata = 8'h00;
            end else begin
                d_read = 0;
                d_write = 1;
                d_writedata = write_val;
            end
            
            access_cycles = 0;
            while (d_busywait) begin
                @(posedge clock);
                access_cycles = access_cycles + 1;
                total_cycles = total_cycles + 1;
            end
            @(posedge clock);
            access_cycles = access_cycles + 1;
            total_cycles = total_cycles + 1;
            
            if (is_read) read_result = d_readdata;
            
            d_read = 0;
            d_write = 0;
            
            if (access_cycles <= 3) begin
                d_hits = d_hits + 1;
                if (is_read) begin
                    $display("  D-Cache HIT: Data=0x%02h (%0d cycles)", read_result, access_cycles);
                end else begin
                    $display("  D-Cache HIT: Write completed (%0d cycles)", access_cycles);
                end
            end else begin
                d_misses = d_misses + 1;
                if (is_read) begin
                    $display("  D-Cache MISS: Data=0x%02h (%0d cycles)", read_result, access_cycles);
                end else begin
                    $display("  D-Cache MISS: Write completed (%0d cycles)", access_cycles);
                end
            end
        end
    endtask
    
    // Task for simulating realistic processor execution
    task simulate_instruction_execution;
        input [31:0] pc;
        input [7:0] operand1_addr, operand2_addr, result_addr;
        input [127:0] inst_name;
        begin
            $display("\n--- SIMULATING: %s ---", inst_name);
            
            // 1. Instruction fetch phase
            fetch_instruction(pc, "Instruction Fetch");
            
            // 2. Operand fetch phase (if memory operands)
            if (operand1_addr != 8'hFF) begin
                access_data_memory(1, operand1_addr, 8'h00, "Load Operand 1");
            end
            if (operand2_addr != 8'hFF) begin
                access_data_memory(1, operand2_addr, 8'h00, "Load Operand 2");
            end
            
            // 3. Execution phase (simulated delay)
            @(posedge clock);
            total_cycles = total_cycles + 1;
            
            // 4. Result writeback phase (if memory result)
            if (result_addr != 8'hFF) begin
                access_data_memory(0, result_addr, $random % 256, "Store Result");
            end
            
            $display("Instruction completed - Total system cycles: %0d", total_cycles);
        end
    endtask
    
    // Task for concurrent cache access test
    task test_concurrent_access;
        begin
            $display("\n=== CONCURRENT CACHE ACCESS TEST ===");
            $display("Testing system behavior with simultaneous I-Cache and D-Cache activity");
            
            fork
                // Instruction fetch stream
                begin
                    fetch_instruction(32'h00000000, "Concurrent I-Fetch 1");
                    #10;
                    fetch_instruction(32'h00000004, "Concurrent I-Fetch 2");
                    #10;
                    fetch_instruction(32'h00000008, "Concurrent I-Fetch 3");
                end
                
                // Data access stream  
                begin
                    #5;
                    access_data_memory(0, 8'h10, 8'hAA, "Concurrent D-Write 1");
                    #15;
                    access_data_memory(1, 8'h10, 8'h00, "Concurrent D-Read 1");
                    #15;
                    access_data_memory(0, 8'h14, 8'hBB, "Concurrent D-Write 2");
                end
            join
            
            concurrent_operations = concurrent_operations + 1;
            $display("Concurrent access test completed");
        end
    endtask
    
    // Task for cache performance comparison
    task analyze_cache_performance;
        real i_hit_ratio, d_hit_ratio;
        real avg_i_cycles, avg_d_cycles;
        begin
            $display("\n=== INTEGRATED CACHE PERFORMANCE ANALYSIS ===");
            
            // Calculate performance metrics
            i_hit_ratio = (i_hits * 100.0) / i_cache_accesses;
            d_hit_ratio = (d_hits * 100.0) / d_cache_accesses;
            
            $display("Instruction Cache Performance:");
            $display("  Total accesses: %0d", i_cache_accesses);
            $display("  Hits: %0d, Misses: %0d", i_hits, i_misses);
            $display("  Hit ratio: %0.1f%%", i_hit_ratio);
            
            $display("Data Cache Performance:");
            $display("  Total accesses: %0d", d_cache_accesses);
            $display("  Hits: %0d, Misses: %0d", d_hits, d_misses);
            $display("  Hit ratio: %0.1f%%", d_hit_ratio);
            
            $display("System Performance:");
            $display("  Total simulation cycles: %0d", total_cycles);
            $display("  Memory operations: %0d", i_cache_accesses + d_cache_accesses);
            $display("  Average cycles per memory op: %0.1f", 
                     (total_cycles * 1.0) / (i_cache_accesses + d_cache_accesses));
            
            $display("Cache Efficiency Comparison:");
            if (i_hit_ratio > d_hit_ratio) begin
                $display("  Instruction cache shows better locality (%.1f%% vs %.1f%%)", 
                         i_hit_ratio, d_hit_ratio);
                $display("  Reason: Sequential instruction execution pattern");
            end else begin
                $display("  Data cache shows better locality (%.1f%% vs %.1f%%)", 
                         d_hit_ratio, i_hit_ratio);
                $display("  Reason: Data reuse patterns in test");
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("====================================================================");
        $display("Integrated Cache System Testbench");
        $display("Testing instruction and data caches in unified system scenario");
        $display("====================================================================");
        
        // Enhanced waveform generation for system-level analysis
        $dumpfile("cache_integration_system.vcd");
        $dumpvars(0, cache_integration_tb);
        
        // Monitor both cache internal states for comparison
        $dumpvars(1, instruction_cache.state);
        $dumpvars(1, instruction_cache.hit);
        $dumpvars(1, instruction_cache.miss);
        $dumpvars(1, data_cache_inst.state);
        $dumpvars(1, data_cache_inst.hit);
        $dumpvars(1, data_cache_inst.miss);
        $dumpvars(1, data_cache_inst.dirty);
        
        // Initialize system
        clock = 0;
        reset = 1;
        i_address = 0;
        d_read = 0;
        d_write = 0;
        d_address = 0;
        d_writedata = 0;
        
        test_count = 0;
        total_cycles = 0;
        i_cache_accesses = 0;
        d_cache_accesses = 0;
        i_hits = 0; i_misses = 0;
        d_hits = 0; d_misses = 0;
        concurrent_operations = 0;
        
        #20;
        reset = 0;
        #10;
        
        $display("\n--- BASIC SYSTEM OPERATION TEST ---");
        
        // Simulate realistic instruction execution patterns
        simulate_instruction_execution(32'h00000000, 8'h20, 8'h24, 8'h28, "ADD R1, MEM[32], MEM[36]");
        simulate_instruction_execution(32'h00000004, 8'h28, 8'hFF, 8'h2C, "STORE MEM[44], R1");
        simulate_instruction_execution(32'h00000008, 8'h30, 8'h34, 8'hFF, "CMP MEM[48], MEM[52]");
        simulate_instruction_execution(32'h0000000C, 8'hFF, 8'hFF, 8'hFF, "JMP (no memory access)");
        
        $display("\n--- INSTRUCTION CACHE LOCALITY TEST ---");
        
        // Sequential instruction fetching (should demonstrate high hit ratio)
        fetch_instruction(32'h00000000, "Sequential - Instruction 0");
        fetch_instruction(32'h00000004, "Sequential - Instruction 1");  // Same block
        fetch_instruction(32'h00000008, "Sequential - Instruction 2");  // Same block
        fetch_instruction(32'h0000000C, "Sequential - Instruction 3");  // Same block
        fetch_instruction(32'h00000010, "Sequential - Instruction 4");  // New block
        
        $display("\n--- DATA CACHE LOCALITY TEST ---");
        
        // Data access with spatial and temporal locality
        access_data_memory(0, 8'h40, 8'h11, "Write data[64]");
        access_data_memory(0, 8'h41, 8'h22, "Write data[65]");  // Same block
        access_data_memory(0, 8'h42, 8'h33, "Write data[66]");  // Same block
        access_data_memory(1, 8'h40, 8'h00, "Re-read data[64]"); // Temporal locality
        access_data_memory(1, 8'h41, 8'h00, "Re-read data[65]"); // Temporal locality
        
        $display("\n--- CACHE CONFLICT TEST ---");
        
        // Test cache conflicts in both caches
        fetch_instruction(32'h00000010, "I-Cache line conflict test 1");
        fetch_instruction(32'h00000090, "I-Cache line conflict test 2"); // Different tag, same index
        fetch_instruction(32'h00000010, "I-Cache line conflict test 3"); // Should miss again
        
        access_data_memory(0, 8'h50, 8'hAA, "D-Cache conflict 1");
        access_data_memory(0, 8'hD0, 8'hBB, "D-Cache conflict 2");  // Different tag, same index
        access_data_memory(1, 8'h50, 8'h00, "D-Cache conflict 3"); // Should miss again
        
        $display("\n--- CONCURRENT ACCESS PATTERNS ---");
        test_concurrent_access();
        
        $display("\n--- WRITE-BACK INTERACTION TEST ---");
        
        // Test data cache write-back while instruction cache is active
        $display("Testing data cache write-back during instruction fetches:");
        
        fork
            begin
                // Cause write-back scenario
                access_data_memory(0, 8'h60, 8'hCC, "Setup for write-back 1");
                access_data_memory(0, 8'h61, 8'hDD, "Modify cached data");
                access_data_memory(0, 8'hE0, 8'hEE, "Force write-back"); // Conflict
            end
            
            begin
                #25; // Stagger instruction fetches
                fetch_instruction(32'h00000020, "Instruction during write-back 1");
                #30;
                fetch_instruction(32'h00000024, "Instruction during write-back 2");
            end
        join
        
        $display("\n--- SYSTEM PERFORMANCE ANALYSIS ---");
        analyze_cache_performance();
        
        $display("\n--- CACHE SYSTEM CHARACTERISTICS ---");
        $display("System Configuration:");
        $display("  Instruction Cache: 8 lines × 16 bytes = 128 bytes total");
        $display("  Data Cache: 8 lines × 4 bytes = 32 bytes total");
        $display("  Memory Latency: 40ns for both instruction and data memory");
        $display("  Cache Policies: Direct-mapped with write-back (data only)");
        
        $display("\n--- GTKWave SYSTEM ANALYSIS GUIDE ---");
        $display("====================================================================");
        $display("Integrated Cache System Analysis in GTKWave:");
        $display("");
        $display("Group 1 - System Control:");
        $display("  - clock, reset (system-wide timing)");
        $display("  - total_cycles (performance tracking)");
        $display("");
        $display("Group 2 - Instruction Cache Interface:");
        $display("  - i_address[31:0] (PC values)");
        $display("  - i_readdata[31:0] (fetched instructions)");
        $display("  - i_busywait (I-cache stall signal)");
        $display("  - instruction_cache.state, .hit, .miss");
        $display("");
        $display("Group 3 - Data Cache Interface:");
        $display("  - d_read, d_write (operation type)");
        $display("  - d_address[7:0], d_writedata[7:0], d_readdata[7:0]");
        $display("  - d_busywait (D-cache stall signal)");
        $display("  - data_cache_inst.state, .hit, .miss, .dirty");
        $display("");
        $display("Group 4 - Memory Interface Activity:");
        $display("  - i_mem_read, i_mem_address, i_mem_busywait");
        $display("  - d_mem_read, d_mem_write, d_mem_address, d_mem_busywait");
        $display("");
        $display("System Analysis Focus:");
        $display("1. Cache Interaction Patterns:");
        $display("   - Observe concurrent I-cache and D-cache operations");
        $display("   - Compare access patterns and locality behavior");
        $display("   - Analyze system-level performance impact");
        $display("");
        $display("2. Memory Bus Utilization:");
        $display("   - Monitor memory interface activity");
        $display("   - Identify bus conflicts and arbitration needs");
        $display("   - Compare instruction vs data memory traffic");
        $display("");
        $display("3. Performance Bottlenecks:");
        $display("   - Identify cache miss penalties");
        $display("   - Observe write-back impact on system performance");
        $display("   - Analyze overall memory hierarchy effectiveness");
        $display("====================================================================");
        
        #100;
        $finish;
    end
    
endmodule