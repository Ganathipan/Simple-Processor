#!/bin/bash
# Cache Testbench Runner Script
# Compiles and runs all cache testbenches with proper file organization

echo "======================================================================"
echo "Cache Memory Testbench Runner"
echo "Testing instruction cache, data cache, and integrated system"
echo "======================================================================"

# Create output directories
mkdir -p Testing_Results/gtkwave_files
mkdir -p Testing_Results/simulation_logs

# Function to run a testbench
run_testbench() {
    local tb_name=$1
    local tb_file=$2
    local dependencies="$3"
    local output_name=$4
    
    echo ""
    echo "--- Running $tb_name ---"
    echo "Compiling: $tb_file"
    
    # Compile
    if iverilog -o "Testing_Results/${output_name}" $tb_file $dependencies > "Testing_Results/simulation_logs/${output_name}_compile.log" 2>&1; then
        echo "✓ Compilation successful"
        
        # Simulate
        echo "Running simulation..."
        if vvp "Testing_Results/${output_name}" > "Testing_Results/simulation_logs/${output_name}_sim.log" 2>&1; then
            echo "✓ Simulation completed successfully"
            
            # Move VCD files to organized location
            if [ -f "instruction_cache_comprehensive.vcd" ]; then
                mv "instruction_cache_comprehensive.vcd" "Testing_Results/gtkwave_files/"
            fi
            if [ -f "data_cache_comprehensive.vcd" ]; then
                mv "data_cache_comprehensive.vcd" "Testing_Results/gtkwave_files/"
            fi
            if [ -f "cache_integration_system.vcd" ]; then
                mv "cache_integration_system.vcd" "Testing_Results/gtkwave_files/"
            fi
            
            echo "✓ Waveform files moved to Testing_Results/gtkwave_files/"
            echo "  Log files saved to Testing_Results/simulation_logs/"
        else
            echo "✗ Simulation failed - check Testing_Results/simulation_logs/${output_name}_sim.log"
            return 1
        fi
    else
        echo "✗ Compilation failed - check Testing_Results/simulation_logs/${output_name}_compile.log"
        return 1
    fi
    
    return 0
}

# Test 1: Instruction Cache
echo ""
echo "========================================"
echo "Test 1: Instruction Cache Verification"
echo "========================================"
run_testbench \
    "Instruction Cache Testbench" \
    "Testing_Results/CacheTestbenches/instruction_cache_tb.v" \
    "CacheMemory/instructionCache.v CacheMemory/instructionMem.v" \
    "inst_cache_test"

# Test 2: Data Cache  
echo ""
echo "========================================"
echo "Test 2: Data Cache Verification"
echo "========================================"
run_testbench \
    "Data Cache Testbench" \
    "Testing_Results/CacheTestbenches/data_cache_tb.v" \
    "CacheMemory/dataMemCache.v CacheMemory/dataMemory.v" \
    "data_cache_test"

# Test 3: Integrated Cache System
echo ""
echo "========================================"  
echo "Test 3: Integrated Cache System"
echo "========================================"
run_testbench \
    "Integrated Cache System Testbench" \
    "Testing_Results/CacheTestbenches/cache_integration_tb.v" \
    "CacheMemory/instructionCache.v CacheMemory/instructionMem.v CacheMemory/dataMemCache.v CacheMemory/dataMemory.v" \
    "cache_system_test"

# Summary
echo ""
echo "======================================================================"
echo "Cache Testbench Summary"
echo "======================================================================"
echo ""
echo "All cache testbenches completed!"
echo ""
echo "Generated Files:"
echo "  Waveforms: Testing_Results/gtkwave_files/"
echo "    - instruction_cache_comprehensive.vcd"
echo "    - data_cache_comprehensive.vcd" 
echo "    - cache_integration_system.vcd"
echo ""
echo "  Simulation Logs: Testing_Results/simulation_logs/"
echo "    - inst_cache_test_compile.log & inst_cache_test_sim.log"
echo "    - data_cache_test_compile.log & data_cache_test_sim.log"
echo "    - cache_system_test_compile.log & cache_system_test_sim.log"
echo ""
echo "GTKWave Analysis Commands:"
echo "  gtkwave Testing_Results/gtkwave_files/instruction_cache_comprehensive.vcd"
echo "  gtkwave Testing_Results/gtkwave_files/data_cache_comprehensive.vcd"
echo "  gtkwave Testing_Results/gtkwave_files/cache_integration_system.vcd"
echo ""
echo "For detailed analysis instructions, see TESTBENCH_USAGE_GUIDE.md"
echo "======================================================================"