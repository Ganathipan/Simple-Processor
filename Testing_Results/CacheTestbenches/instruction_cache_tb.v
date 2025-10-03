// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// instruction_cache_tb.v - Comprehensive Instruction Cache Testbench
// Purpose: Thorough verification of instruction cache functionality including
//          cache hits/misses, block fetching, timing analysis, and performance
//          characterization. Designed for GTKWave analysis and educational insight.
// -----------------------------------------------------------------------------

`timescale 1ns/100ps

// Comprehensive Instruction Cache Testbench
// Tests cache behavior, memory interface, and performance characteristics
module instruction_cache_tb;

    // CPU Interface Signals
    reg clock;
    reg reset;
    reg [31:0] address;
    wire [31:0] readdata;
    wire busywait;
    
    // Memory Interface Signals (between cache and main memory)
    wire mem_read;
    wire [5:0] mem_address;
    wire [127:0] mem_readdata;
    wire mem_busywait;
    
    // Test control variables
    integer test_count;
    integer hit_count, miss_count;
    integer total_cycles, access_cycles;
    integer start_time, end_time;
    reg [31:0] expected_data;
    
    // Performance monitoring
    reg [31:0] test_addresses [0:15];  // Array of test addresses
    reg [31:0] expected_results [0:15]; // Expected instruction data
    integer i;
    
    // Instantiate instruction cache
    inst_cache uut_cache (
        .clock(clock),
        .reset(reset),
        .address(address),
        .readdata(readdata),
        .busywait(busywait),
        .mem_read(mem_read),
        .mem_address(mem_address),
        .mem_readdata(mem_readdata),
        .mem_busywait(mem_busywait)
    );
    
    // Instantiate instruction memory
    instruction_memory uut_memory (
        .clock(clock),
        .read(mem_read),
        .address(mem_address),
        .readinst(mem_readdata),
        .busywait(mem_busywait)
    );
    
    // Clock generation
    always #5 clock = ~clock;
    
    // Test task for single instruction fetch
    task test_instruction_fetch;
        input [31:0] test_addr;
        input [31:0] expected_inst;
        input [127:0] test_name;
        integer fetch_start, fetch_end, fetch_cycles;
        begin
            test_count = test_count + 1;
            $display("\n=== TEST %0d: %s ===", test_count, test_name);
            $display("Address: 0x%08h, Expected: 0x%08h", test_addr, expected_inst);
            
            fetch_start = total_cycles;
            address = test_addr;
            
            // Wait for fetch completion
            while (busywait) begin
                @(posedge clock);
                total_cycles = total_cycles + 1;
            end
            @(posedge clock);
            total_cycles = total_cycles + 1;
            
            fetch_end = total_cycles;
            fetch_cycles = fetch_end - fetch_start;
            
            // Verify result
            if (readdata === expected_inst) begin
                $display("✓ PASS: Instruction = 0x%08h (Cycles: %0d)", readdata, fetch_cycles);
                if (fetch_cycles <= 2) begin
                    hit_count = hit_count + 1;
                    $display("  Cache HIT detected (fast access)");
                end else begin
                    miss_count = miss_count + 1;
                    $display("  Cache MISS detected (memory access required)");
                end
            end else begin
                $display("✗ FAIL: Expected 0x%08h, Got 0x%08h", expected_inst, readdata);
            end
            
            access_cycles = access_cycles + fetch_cycles;
        end
    endtask
    
    // Task for testing cache line locality
    task test_spatial_locality;
        input [31:0] base_addr;
        input [127:0] test_name;
        reg [31:0] block_addresses [0:3];
        integer first_access_cycles, subsequent_cycles;
        integer j;
        begin
            $display("\n=== SPATIAL LOCALITY TEST: %s ===", test_name);
            $display("Base address: 0x%08h", base_addr);
            
            // Generate addresses in same cache block (16-byte aligned)
            block_addresses[0] = {base_addr[31:4], 4'b0000}; // Word 0
            block_addresses[1] = {base_addr[31:4], 4'b0100}; // Word 1  
            block_addresses[2] = {base_addr[31:4], 4'b1000}; // Word 2
            block_addresses[3] = {base_addr[31:4], 4'b1100}; // Word 3
            
            // First access (should miss)
            $display("First access to block (expect miss):");
            start_time = total_cycles;
            address = block_addresses[0];
            while (busywait) begin
                @(posedge clock);
                total_cycles = total_cycles + 1;
            end
            @(posedge clock); total_cycles = total_cycles + 1;
            first_access_cycles = total_cycles - start_time;
            $display("  Address 0x%08h: %0d cycles (MISS)", address, first_access_cycles);
            
            // Subsequent accesses (should hit)
            $display("Subsequent accesses to same block (expect hits):");
            for (j = 1; j < 4; j = j + 1) begin
                start_time = total_cycles;
                address = block_addresses[j];
                while (busywait) begin
                    @(posedge clock);
                    total_cycles = total_cycles + 1;
                end
                @(posedge clock); total_cycles = total_cycles + 1;
                subsequent_cycles = total_cycles - start_time;
                $display("  Address 0x%08h: %0d cycles %s", 
                         address, subsequent_cycles,
                         (subsequent_cycles <= 2) ? "(HIT)" : "(MISS)");
            end
            
            $display("Spatial locality performance:");
            $display("  First access: %0d cycles", first_access_cycles);
            $display("  Hit ratio in block: %0d/3", (subsequent_cycles <= 2) ? 3 : 0);
        end
    endtask
    
    // Task for cache capacity test
    task test_cache_capacity;
        reg [31:0] test_addr;
        integer cache_lines_tested;
        integer line_idx;
        begin
            $display("\n=== CACHE CAPACITY TEST ===");
            $display("Testing all 8 cache lines for eviction behavior");
            
            cache_lines_tested = 0;
            
            // Test addresses that map to different cache lines
            for (line_idx = 0; line_idx < 8; line_idx = line_idx + 1) begin
                test_addr = {25'b0, line_idx[2:0], 4'b0000}; // Different index, same tag
                $display("Testing cache line %0d (addr: 0x%08h):", line_idx, test_addr);
                
                start_time = total_cycles;
                address = test_addr;
                while (busywait) begin
                    @(posedge clock);
                    total_cycles = total_cycles + 1;
                end
                @(posedge clock); total_cycles = total_cycles + 1;
                end_time = total_cycles - start_time;
                
                $display("  Access time: %0d cycles %s", 
                         end_time, (end_time > 2) ? "(MISS - first access)" : "(HIT - cached)");
                cache_lines_tested = cache_lines_tested + 1;
            end
            
            $display("Cache capacity test completed: %0d/8 lines tested", cache_lines_tested);
        end
    endtask
    
    // Task for testing cache replacement
    task test_cache_replacement;
        reg [31:0] addr_set1, addr_set2;
        integer initial_cycles, eviction_cycles, reload_cycles;
        begin
            $display("\n=== CACHE REPLACEMENT TEST ===");
            $display("Testing cache line eviction and replacement");
            
            // Use addresses that map to same cache line but different tags
            addr_set1 = 32'h00000010; // Tag=0, Index=1, Offset=0
            addr_set2 = 32'h00000090; // Tag=1, Index=1, Offset=0 (same index, different tag)
            
            $display("Phase 1: Load first address (0x%08h)", addr_set1);
            start_time = total_cycles;
            address = addr_set1;
            while (busywait) begin
                @(posedge clock);
                total_cycles = total_cycles + 1;
            end
            @(posedge clock); total_cycles = total_cycles + 1;
            initial_cycles = total_cycles - start_time;
            $display("  Initial load: %0d cycles", initial_cycles);
            
            $display("Phase 2: Load second address (0x%08h) - should evict first", addr_set2);
            start_time = total_cycles;
            address = addr_set2;
            while (busywait) begin
                @(posedge clock);
                total_cycles = total_cycles + 1;
            end
            @(posedge clock); total_cycles = total_cycles + 1;
            eviction_cycles = total_cycles - start_time;
            $display("  Eviction load: %0d cycles", eviction_cycles);
            
            $display("Phase 3: Reload first address (0x%08h) - should miss again", addr_set1);
            start_time = total_cycles;
            address = addr_set1;
            while (busywait) begin
                @(posedge clock);
                total_cycles = total_cycles + 1;
            end
            @(posedge clock); total_cycles = total_cycles + 1;
            reload_cycles = total_cycles - start_time;
            $display("  Reload cycles: %0d cycles", reload_cycles);
            
            $display("Replacement behavior:");
            $display("  All accesses should be misses (>2 cycles each)");
            $display("  Demonstrates direct-mapped cache conflict behavior");
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("====================================================================");
        $display("Comprehensive Instruction Cache Testbench");
        $display("Testing cache functionality, performance, and GTKWave analysis");
        $display("====================================================================");
        
        // Enhanced waveform generation for cache analysis
        $dumpfile("instruction_cache_comprehensive.vcd");
        $dumpvars(0, instruction_cache_tb);
        
        // Monitor internal cache signals for detailed analysis
        $dumpvars(1, uut_cache.state);
        $dumpvars(1, uut_cache.hit);
        $dumpvars(1, uut_cache.miss);
        $dumpvars(1, uut_cache.index);
        $dumpvars(1, uut_cache.tag);
        $dumpvars(1, uut_cache.offset);
        // Note: Memory arrays (valid_array, tag_array, data_array) monitored through $dumpvars(0, ...)
        
        // Initialize
        clock = 0;
        reset = 1;
        address = 0;
        test_count = 0;
        hit_count = 0;
        miss_count = 0;
        total_cycles = 0;
        access_cycles = 0;
        
        #20;
        reset = 0;
        #10;
        
        $display("\n--- BASIC FUNCTIONALITY TESTS ---");
        
        // Test basic instruction fetches (addresses from memory initialization)
        test_instruction_fetch(32'h00000000, 32'b00011001_00000000_00000100_00000000, "Basic fetch - Instruction 0");
        test_instruction_fetch(32'h00000004, 32'b00100011_00000000_00000101_00000000, "Basic fetch - Instruction 1");
        test_instruction_fetch(32'h00000008, 32'b00000101_00000100_00000110_00000010, "Basic fetch - Instruction 2");
        test_instruction_fetch(32'h0000000C, 32'b01011010_00000000_00000001_00000000, "Basic fetch - Instruction 3");
        
        // Test cache hit behavior (re-access same instructions)
        $display("\n--- CACHE HIT TESTS ---");
        test_instruction_fetch(32'h00000000, 32'b00011001_00000000_00000100_00000000, "Cache hit - Instruction 0");
        test_instruction_fetch(32'h00000004, 32'b00100011_00000000_00000101_00000000, "Cache hit - Instruction 1");
        
        // Test spatial locality within cache blocks
        test_spatial_locality(32'h00000000, "Block 0 spatial locality");
        test_spatial_locality(32'h00000020, "Block 2 spatial locality");
        
        // Test cache capacity and line utilization
        test_cache_capacity();
        
        // Test cache replacement behavior
        test_cache_replacement();
        
        $display("\n--- EDGE CASE TESTS ---");
        
        // Test unaligned access behavior
        test_instruction_fetch(32'h00000002, 32'h00000000, "Unaligned access test");
        test_instruction_fetch(32'h00000006, 32'h00000000, "Unaligned access test");
        
        // Test boundary conditions
        test_instruction_fetch(32'h000003FC, 32'h00000000, "Near boundary access");
        test_instruction_fetch(32'h00000400, 32'h00000000, "Boundary cross access");
        
        $display("\n--- PERFORMANCE ANALYSIS ---");
        
        $display("Cache Performance Summary:");
        $display("  Total instruction fetches: %0d", test_count);
        $display("  Cache hits: %0d", hit_count);
        $display("  Cache misses: %0d", miss_count);
        $display("  Hit ratio: %0.1f%%", (hit_count * 100.0) / test_count);
        $display("  Average cycles per access: %0.1f", (access_cycles * 1.0) / test_count);
        $display("  Total simulation cycles: %0d", total_cycles);
        
        $display("\n--- CACHE CHARACTERISTICS ---");
        $display("Cache Configuration:");
        $display("  Type: Direct-mapped instruction cache");
        $display("  Capacity: 128 bytes (8 lines × 16 bytes per line)");
        $display("  Block size: 16 bytes (4 instructions)");
        $display("  Address breakdown: [31:7] Tag, [6:4] Index, [3:0] Offset");
        $display("  Memory latency: ~40ns (typical DRAM access time)");
        
        $display("\n--- GTKWave ANALYSIS INSTRUCTIONS ---");
        $display("====================================================================");
        $display("GTKWave Signal Organization for Cache Analysis:");
        $display("");
        $display("Group 1 - CPU Interface:");
        $display("  - clock, reset");
        $display("  - address[31:0] (instruction address from CPU)");
        $display("  - readdata[31:0] (instruction data to CPU)");
        $display("  - busywait (CPU stall signal)");
        $display("");
        $display("Group 2 - Memory Interface:");
        $display("  - mem_read (memory access request)");
        $display("  - mem_address[5:0] (block address to memory)");
        $display("  - mem_readdata[127:0] (128-bit block from memory)");
        $display("  - mem_busywait (memory busy signal)");
        $display("");
        $display("Group 3 - Cache Internal Signals:");
        $display("  - uut_cache.state (FSM state: IDLE/MEM_READ)");
        $display("  - uut_cache.hit, uut_cache.miss (cache hit/miss detection)");
        $display("  - uut_cache.index[2:0] (cache line selection)");
        $display("  - uut_cache.tag[25:0] (address tag for comparison)");
        $display("  - uut_cache.offset[3:0] (word selection within block)");
        $display("");
        $display("Group 4 - Cache Arrays:");
        $display("  - uut_cache.valid_array[7:0] (valid bits for all lines)");
        $display("  - uut_cache.tag_array (stored tags for comparison)");
        $display("  - uut_cache.data_array (cached instruction blocks)");
        $display("");
        $display("Analysis Focus Areas:");
        $display("1. Cache Miss Behavior:");
        $display("   - Observe busywait assertion on miss");
        $display("   - Track mem_read activation and mem_address");
        $display("   - Monitor 40ns memory latency");
        $display("   - Watch cache array updates");
        $display("");
        $display("2. Cache Hit Behavior:");
        $display("   - Fast access (1-2 cycles)");
        $display("   - No memory interface activity");
        $display("   - Direct readdata update");
        $display("");
        $display("3. Spatial Locality:");
        $display("   - First access to block causes miss and block fetch");
        $display("   - Subsequent accesses within block are hits");
        $display("   - Word selection via offset bits");
        $display("");
        $display("4. Cache Replacement:");
        $display("   - Same index, different tag causes eviction");
        $display("   - Valid bit and tag updates");
        $display("   - Performance impact of conflicts");
        $display("====================================================================");
        
        #100;
        $finish;
    end
    
endmodule