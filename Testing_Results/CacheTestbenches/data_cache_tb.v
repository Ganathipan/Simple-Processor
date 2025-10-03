// -----------------------------------------------------------------------------
// Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]
// Date: 2025-06-22
// Institution: Computer Engineering Department, Faculty of Engineering, UOP
// -----------------------------------------------------------------------------
// data_cache_tb.v - Comprehensive Data Cache Testbench
// Purpose: Thorough verification of data cache functionality including
//          read/write operations, cache hits/misses, write-back policy,
//          and performance characterization. Designed for GTKWave analysis.
// -----------------------------------------------------------------------------

`timescale 1ns/100ps

// Comprehensive Data Cache Testbench
// Tests cache behavior, write-back policy, and memory interface
module data_cache_tb;

    // CPU Interface Signals
    reg clk, reset;
    reg read, write;
    reg [7:0] address;
    reg [7:0] writedata;
    wire [7:0] readdata;
    wire busywait;
    
    // Memory Interface Signals (between cache and main memory)
    wire mem_read, mem_write;
    wire [5:0] mem_address;
    wire [31:0] mem_writedata;
    wire [31:0] mem_readdata;
    wire mem_busywait;
    
    // Test control variables
    integer test_count;
    integer hit_count, miss_count, writeback_count;
    integer total_cycles, access_cycles;
    integer start_time, end_time;
    reg [7:0] test_data;
    
    // Test memory initialization
    reg [7:0] memory_init [255:0];
    integer i;
    
    // Instantiate data cache
    data_cache uut_cache (
        .clk(clk),
        .reset(reset),
        .read(read),
        .write(write),
        .address(address),
        .writedata(writedata),
        .readdata(readdata),
        .busywait(busywait),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_writedata(mem_writedata),
        .mem_readdata(mem_readdata),
        .mem_busywait(mem_busywait)
    );
    
    // Instantiate data memory
    data_memory uut_memory (
        .clock(clk),
        .reset(reset),
        .read(mem_read),
        .write(mem_write),
        .address(mem_address),
        .writedata(mem_writedata),
        .readdata(mem_readdata),
        .busywait(mem_busywait)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Task for data read operation
    task test_data_read;
        input [7:0] test_addr;
        input [7:0] expected_data;
        input [127:0] test_name;
        integer read_start, read_end, read_cycles;
        begin
            test_count = test_count + 1;
            $display("\n=== TEST %0d: %s ===", test_count, test_name);
            $display("READ Address: 0x%02h, Expected: 0x%02h", test_addr, expected_data);
            
            read_start = total_cycles;
            
            // Initiate read operation
            @(negedge clk);
            address = test_addr;
            read = 1;
            write = 0;
            
            // Wait for completion
            while (busywait) begin
                @(posedge clk);
                total_cycles = total_cycles + 1;
            end
            @(posedge clk);
            total_cycles = total_cycles + 1;
            
            // Deassert read
            read = 0;
            
            read_end = total_cycles;
            read_cycles = read_end - read_start;
            
            // Verify result
            if (readdata === expected_data) begin
                $display("✓ PASS: Data = 0x%02h (Cycles: %0d)", readdata, read_cycles);
                if (read_cycles <= 3) begin
                    hit_count = hit_count + 1;
                    $display("  Cache HIT detected (fast access)");
                end else begin
                    miss_count = miss_count + 1;
                    $display("  Cache MISS detected (memory fetch required)");
                end
            end else begin
                $display("✗ FAIL: Expected 0x%02h, Got 0x%02h", expected_data, readdata);
            end
            
            access_cycles = access_cycles + read_cycles;
        end
    endtask
    
    // Task for data write operation
    task test_data_write;
        input [7:0] test_addr;
        input [7:0] test_data_val;
        input [127:0] test_name;
        integer write_start, write_end, write_cycles;
        begin
            test_count = test_count + 1;
            $display("\n=== TEST %0d: %s ===", test_count, test_name);
            $display("WRITE Address: 0x%02h, Data: 0x%02h", test_addr, test_data_val);
            
            write_start = total_cycles;
            
            // Initiate write operation
            @(negedge clk);
            address = test_addr;
            writedata = test_data_val;
            read = 0;
            write = 1;
            
            // Wait for completion
            while (busywait) begin
                @(posedge clk);
                total_cycles = total_cycles + 1;
            end
            @(posedge clk);
            total_cycles = total_cycles + 1;
            
            // Deassert write
            write = 0;
            
            write_end = total_cycles;
            write_cycles = write_end - write_start;
            
            $display("✓ WRITE completed in %0d cycles", write_cycles);
            if (write_cycles <= 3) begin
                hit_count = hit_count + 1;
                $display("  Cache HIT - write to existing cache line");
            end else begin
                miss_count = miss_count + 1;
                $display("  Cache MISS - fetch required before write");
            end
            
            access_cycles = access_cycles + write_cycles;
        end
    endtask
    
    // Task for write-back verification
    task test_writeback_behavior;
        reg [7:0] addr1, addr2;
        reg [7:0] data1, data2;
        begin
            $display("\n=== WRITE-BACK POLICY TEST ===");
            
            // Use addresses that map to same cache line (same index, different tag)
            addr1 = 8'h10; // Tag=0, Index=4, Offset=0
            addr2 = 8'h90; // Tag=4, Index=4, Offset=0 (same index, different tag)
            data1 = 8'hAA;
            data2 = 8'hBB;
            
            $display("Phase 1: Write to first address (0x%02h)", addr1);
            test_data_write(addr1, data1, "Initial write - should miss and fetch");
            
            $display("Phase 2: Modify the cached data");
            test_data_write(addr1, 8'hCC, "Modify cached data - should hit");
            
            $display("Phase 3: Write to conflicting address (0x%02h)", addr2);
            $display("  This should trigger write-back of dirty cache line");
            
            // Monitor for write-back operation
            start_time = total_cycles;
            test_data_write(addr2, data2, "Conflicting write - should cause write-back");
            
            if (mem_write) writeback_count = writeback_count + 1;
            
            $display("Phase 4: Verify write-back occurred by reading original address");
            test_data_read(addr1, 8'hCC, "Read after eviction - should miss but data preserved");
        end
    endtask
    
    // Task for cache block locality test
    task test_block_locality;
        reg [7:0] base_addr;
        reg [7:0] test_addrs [0:3];
        reg [7:0] test_values [0:3];
        integer j;
        begin
            $display("\n=== CACHE BLOCK LOCALITY TEST ===");
            
            base_addr = 8'h20; // Use cache line 0
            
            // Generate addresses within same cache block (4-byte block)
            test_addrs[0] = {base_addr[7:2], 2'b00}; // Byte 0 of block
            test_addrs[1] = {base_addr[7:2], 2'b01}; // Byte 1 of block
            test_addrs[2] = {base_addr[7:2], 2'b10}; // Byte 2 of block  
            test_addrs[3] = {base_addr[7:2], 2'b11}; // Byte 3 of block
            
            test_values[0] = 8'h11;
            test_values[1] = 8'h22;
            test_values[2] = 8'h33;
            test_values[3] = 8'h44;
            
            $display("Testing spatial locality within cache block:");
            $display("Block base: 0x%02h", {base_addr[7:2], 2'b00});
            
            // First access should miss and fetch block
            $display("First access (should miss and fetch block):");
            test_data_write(test_addrs[0], test_values[0], "Write byte 0 - MISS expected");
            
            // Subsequent accesses should hit
            $display("Subsequent accesses within same block (should hit):");
            for (j = 1; j < 4; j = j + 1) begin
                test_data_write(test_addrs[j], test_values[j], "Write within block - HIT expected");
            end
            
            // Read back to verify
            $display("Read back verification (should all hit):");
            for (j = 0; j < 4; j = j + 1) begin
                test_data_read(test_addrs[j], test_values[j], "Read within block - HIT expected");
            end
        end
    endtask
    
    // Task for cache capacity and eviction test
    task test_cache_eviction;
        reg [7:0] test_addresses [0:7];
        reg [7:0] test_data_values [0:7];
        integer k;
        begin
            $display("\n=== CACHE CAPACITY AND EVICTION TEST ===");
            
            // Fill all 8 cache lines with unique data
            for (k = 0; k < 8; k = k + 1) begin
                test_addresses[k] = {3'b000, k[2:0], 2'b00}; // Different index for each
                test_data_values[k] = 8'h50 + k;
            end
            
            $display("Phase 1: Fill all cache lines");
            for (k = 0; k < 8; k = k + 1) begin
                test_data_write(test_addresses[k], test_data_values[k], "Fill cache line");
            end
            
            $display("Phase 2: Verify all lines are cached (should all hit)");
            for (k = 0; k < 8; k = k + 1) begin
                test_data_read(test_addresses[k], test_data_values[k], "Read cached line");
            end
            
            $display("Phase 3: Test eviction with conflicting addresses");
            for (k = 0; k < 8; k = k + 1) begin
                // Use same index but different tag to force eviction
                test_data_write({3'b001, k[2:0], 2'b00}, 8'hA0 + k, "Evict and replace");
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("====================================================================");
        $display("Comprehensive Data Cache Testbench");
        $display("Testing read/write operations, write-back policy, and performance");
        $display("====================================================================");
        
        // Enhanced waveform generation for cache analysis
        $dumpfile("data_cache_comprehensive.vcd");
        $dumpvars(0, data_cache_tb);
        
        // Monitor internal cache signals for detailed analysis
        $dumpvars(1, uut_cache.state);
        $dumpvars(1, uut_cache.hit);
        $dumpvars(1, uut_cache.miss);
        $dumpvars(1, uut_cache.dirty);
        $dumpvars(1, uut_cache.valid);
        $dumpvars(1, uut_cache.addr_tag);
        $dumpvars(1, uut_cache.addr_index);
        $dumpvars(1, uut_cache.addr_offset);
        // Note: Memory arrays (tags, valids, dirtys, data_blocks) monitored through $dumpvars(0, ...)
        
        // Initialize test environment
        clk = 0;
        reset = 1;
        read = 0;
        write = 0;
        address = 0;
        writedata = 0;
        test_count = 0;
        hit_count = 0;
        miss_count = 0;
        writeback_count = 0;
        total_cycles = 0;
        access_cycles = 0;
        
        // Initialize memory with test patterns
        for (i = 0; i < 256; i = i + 1) begin
            memory_init[i] = i[7:0]; // Simple pattern: address = data
        end
        
        #20;
        reset = 0;
        #10;
        
        $display("\n--- BASIC READ OPERATIONS ---");
        
        // Test basic read operations
        test_data_read(8'h00, 8'h00, "Basic read - Address 0x00");
        test_data_read(8'h01, 8'h01, "Basic read - Address 0x01");
        test_data_read(8'h04, 8'h04, "Basic read - Address 0x04");
        test_data_read(8'h08, 8'h08, "Basic read - Address 0x08");
        
        $display("\n--- CACHE HIT TESTS ---");
        
        // Re-read same addresses (should hit)
        test_data_read(8'h00, 8'h00, "Cache hit - Address 0x00");
        test_data_read(8'h01, 8'h01, "Cache hit - Address 0x01");
        
        $display("\n--- BASIC WRITE OPERATIONS ---");
        
        // Test write operations
        test_data_write(8'h10, 8'hAA, "Basic write - Address 0x10");
        test_data_write(8'h11, 8'hBB, "Basic write - Address 0x11");
        test_data_write(8'h14, 8'hCC, "Basic write - Address 0x14");
        
        // Verify writes by reading back
        test_data_read(8'h10, 8'hAA, "Verify write - Address 0x10");
        test_data_read(8'h11, 8'hBB, "Verify write - Address 0x11");
        test_data_read(8'h14, 8'hCC, "Verify write - Address 0x14");
        
        $display("\n--- SPATIAL LOCALITY TESTS ---");
        test_block_locality();
        
        $display("\n--- WRITE-BACK POLICY TESTS ---");
        test_writeback_behavior();
        
        $display("\n--- CACHE CAPACITY TESTS ---");
        test_cache_eviction();
        
        $display("\n--- MIXED READ/WRITE PATTERN ---");
        
        // Alternating read/write pattern
        test_data_write(8'h20, 8'hDE, "Mixed pattern - Write 0x20");
        test_data_read(8'h20, 8'hDE, "Mixed pattern - Read 0x20");
        test_data_write(8'h21, 8'hAD, "Mixed pattern - Write 0x21");
        test_data_read(8'h21, 8'hAD, "Mixed pattern - Read 0x21");
        
        $display("\n--- PERFORMANCE ANALYSIS ---");
        
        $display("Data Cache Performance Summary:");
        $display("  Total memory operations: %0d", test_count);
        $display("  Cache hits: %0d", hit_count);
        $display("  Cache misses: %0d", miss_count);
        $display("  Write-backs detected: %0d", writeback_count);
        $display("  Hit ratio: %0.1f%%", (hit_count * 100.0) / test_count);
        $display("  Average cycles per access: %0.1f", (access_cycles * 1.0) / test_count);
        $display("  Total simulation cycles: %0d", total_cycles);
        
        $display("\n--- CACHE CHARACTERISTICS ---");
        $display("Cache Configuration:");
        $display("  Type: Direct-mapped data cache with write-back");
        $display("  Capacity: 32 bytes (8 lines × 4 bytes per line)");
        $display("  Block size: 4 bytes");
        $display("  Address breakdown: [7:5] Tag, [4:2] Index, [1:0] Offset");
        $display("  Write policy: Write-back with dirty bit tracking");
        $display("  Memory latency: ~40ns (DRAM simulation)");
        
        $display("\n--- GTKWave ANALYSIS INSTRUCTIONS ---");
        $display("====================================================================");
        $display("GTKWave Signal Organization for Data Cache Analysis:");
        $display("");
        $display("Group 1 - CPU Interface:");
        $display("  - clk, reset");
        $display("  - read, write (operation type)");
        $display("  - address[7:0] (data address from CPU)");
        $display("  - writedata[7:0], readdata[7:0] (data flow)");
        $display("  - busywait (CPU stall signal)");
        $display("");
        $display("Group 2 - Memory Interface:");
        $display("  - mem_read, mem_write (memory operations)");
        $display("  - mem_address[5:0] (block address to memory)");
        $display("  - mem_writedata[31:0], mem_readdata[31:0] (block data)");
        $display("  - mem_busywait (memory busy signal)");
        $display("");
        $display("Group 3 - Cache Internal Control:");
        $display("  - uut_cache.state (FSM: IDLE/FETCH/WRITE_BACK)");
        $display("  - uut_cache.hit, uut_cache.miss (hit/miss detection)");
        $display("  - uut_cache.dirty, uut_cache.valid (cache line status)");
        $display("  - uut_cache.addr_tag[2:0] (address tag field)");
        $display("  - uut_cache.addr_index[2:0] (cache line index)");
        $display("  - uut_cache.addr_offset[1:0] (byte offset)");
        $display("");
        $display("Group 4 - Cache Storage Arrays:");
        $display("  - uut_cache.tags[7:0] (tag array)");
        $display("  - uut_cache.valids[7:0] (valid bit array)");
        $display("  - uut_cache.dirtys[7:0] (dirty bit array)");
        $display("  - uut_cache.data_blocks (data storage array)");
        $display("");
        $display("Analysis Focus Areas:");
        $display("1. Cache Miss Handling:");
        $display("   - State transition: IDLE → FETCH");
        $display("   - Memory read operation activation");
        $display("   - Cache line population and tag update");
        $display("");
        $display("2. Cache Hit Operations:");
        $display("   - Fast completion (1-3 cycles)");
        $display("   - Direct data array access");
        $display("   - Dirty bit setting on writes");
        $display("");
        $display("3. Write-Back Policy:");
        $display("   - State transition: IDLE → WRITE_BACK → FETCH");
        $display("   - Dirty cache line eviction to memory");
        $display("   - Memory write followed by new block fetch");
        $display("");
        $display("4. Spatial Locality:");
        $display("   - Block-level caching (4 bytes per block)");
        $display("   - Byte-level access within blocks");
        $display("   - Offset-based byte selection");
        $display("");
        $display("5. Cache Conflicts:");
        $display("   - Same index, different tag scenarios");
        $display("   - Eviction and replacement behavior");
        $display("   - Dirty data preservation");
        $display("====================================================================");
        
        #100;
        $finish;
    end
    
endmodule