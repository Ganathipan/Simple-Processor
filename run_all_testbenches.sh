#!/bin/bash
# =============================================================================
# Comprehensive Processor Testbench Runner Script - Fixed Version
# Author: S. Ganathipan [E/21/148], K. Jarshigan [E/21/188] 
# Purpose: Robust automated testing with timeout protection and proper error handling
# =============================================================================

set -e  # Exit on any error
set -u  # Exit on undefined variables

# =============================================================================
# SCRIPT CONFIGURATION
# =============================================================================

# Timeout settings (in seconds)
readonly COMPILE_TIMEOUT=30
readonly SIMULATION_TIMEOUT=120
readonly SCRIPT_START_TIME=$(date +%s)
readonly MAX_SCRIPT_RUNTIME=1800  # 30 minutes maximum

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m' 
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Test tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Function to check script runtime and prevent infinite loops
check_script_timeout() {
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - SCRIPT_START_TIME))
    
    if [ $elapsed_time -gt $MAX_SCRIPT_RUNTIME ]; then
        echo -e "${RED}❌ SCRIPT TIMEOUT: Maximum runtime exceeded (${MAX_SCRIPT_RUNTIME}s)${NC}"
        echo -e "${RED}Terminating to prevent infinite loop${NC}"
        exit 1
    fi
}

# Function to run command with timeout
run_with_timeout() {
    local timeout_duration=$1
    shift
    local command="$@"
    
    timeout $timeout_duration bash -c "$command"
    return $?
}

# Function to validate file existence
validate_files() {
    local tb_file=$1
    local dependencies=$2
    
    # Check testbench file
    if [ ! -f "$tb_file" ]; then
        echo -e "${RED}❌ Testbench file not found: $tb_file${NC}"
        return 1
    fi
    
    # Check dependencies
    for dep in $dependencies; do
        if [ ! -f "$dep" ]; then
            echo -e "${YELLOW}⚠️  Dependency file not found: $dep${NC}"
            return 1
        fi
    done
    
    return 0
}

# Function to cleanup on exit
cleanup() {
    local exit_code=$?
    echo ""
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    
    # Kill any background processes
    jobs -p | xargs -r kill 2>/dev/null || true
    
    # Remove temporary files
    rm -f *.vcd 2>/dev/null || true
    
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}❌ Script terminated unexpectedly${NC}"
    fi
    
    exit $exit_code
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

# =============================================================================
# DIRECTORY SETUP
# =============================================================================

setup_directories() {
    echo -e "${CYAN}📁 Setting up output directories...${NC}"
    
    # Create directories with proper error checking
    local directories=(
        "Testing_Results/gtkwave_files"
        "Testing_Results/simulation_logs"
        "Testing_Results/executables"
    )
    
    for dir in "${directories[@]}"; do
        if ! mkdir -p "$dir"; then
            echo -e "${RED}❌ Failed to create directory: $dir${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}✅ Directory structure created successfully${NC}"
}

# =============================================================================
# ENHANCED TESTBENCH RUNNER WITH ROBUST ERROR HANDLING
# =============================================================================

run_testbench() {
    local category=$1
    local tb_name=$2
    local tb_file=$3
    local dependencies=$4
    local output_name=$5
    local expected_vcd=$6
    
    # Check script timeout before each test
    check_script_timeout
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}📋 TEST ${TOTAL_TESTS}: ${tb_name}${NC}"
    echo -e "${BLUE}📂 Category: ${category}${NC}"
    echo -e "${YELLOW}📄 File: ${tb_file}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Validate input files
    if ! validate_files "$tb_file" "$dependencies"; then
        echo -e "${YELLOW}⚠️  SKIPPING: Missing required files${NC}"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        return 1
    fi
    
    # Compilation Phase with timeout
    echo -e "⚙️  ${YELLOW}Compiling testbench (timeout: ${COMPILE_TIMEOUT}s)...${NC}"
    
    local compile_cmd="iverilog -o Testing_Results/executables/${output_name} ${tb_file} ${dependencies}"
    local compile_log="Testing_Results/simulation_logs/${output_name}_compile.log"
    
    if run_with_timeout $COMPILE_TIMEOUT "$compile_cmd > $compile_log 2>&1"; then
        echo -e "✅ ${GREEN}Compilation successful${NC}"
    else
        local compile_exit_code=$?
        echo -e "❌ ${RED}Compilation failed (exit code: ${compile_exit_code})${NC}"
        echo -e "📝 Check log: ${compile_log}"
        
        if [ $compile_exit_code -eq 124 ]; then
            echo -e "${RED}⏰ Compilation timed out after ${COMPILE_TIMEOUT}s${NC}"
        fi
        
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    # Simulation Phase with timeout
    echo -e "🔄 ${YELLOW}Running simulation (timeout: ${SIMULATION_TIMEOUT}s)...${NC}"
    
    local sim_cmd="vvp Testing_Results/executables/${output_name}"
    local sim_log="Testing_Results/simulation_logs/${output_name}_sim.log"
    
    if run_with_timeout $SIMULATION_TIMEOUT "$sim_cmd > $sim_log 2>&1"; then
        echo -e "✅ ${GREEN}Simulation completed successfully${NC}"
    else
        local sim_exit_code=$?
        echo -e "❌ ${RED}Simulation failed (exit code: ${sim_exit_code})${NC}"
        echo -e "📝 Check log: ${sim_log}"
        
        if [ $sim_exit_code -eq 124 ]; then
            echo -e "${RED}⏰ Simulation timed out after ${SIMULATION_TIMEOUT}s${NC}"
        fi
        
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    # VCD File Management
    echo -e "📊 ${YELLOW}Managing waveform files...${NC}"
    local vcd_found=false
    
    # Check for expected VCD file
    if [ -f "$expected_vcd" ]; then
        mv "$expected_vcd" "Testing_Results/gtkwave_files/"
        echo -e "📈 ${GREEN}Moved ${expected_vcd} to gtkwave_files/${NC}"
        vcd_found=true
    else
        # Look for any .vcd files in current directory
        for vcd_file in *.vcd; do
            if [ -f "$vcd_file" ]; then
                mv "$vcd_file" "Testing_Results/gtkwave_files/"
                echo -e "� ${GREEN}Moved ${vcd_file} to gtkwave_files/${NC}"
                vcd_found=true
            fi
        done
    fi
    
    if [ "$vcd_found" = false ]; then
        echo -e "⚠️  ${YELLOW}Warning: No VCD files found for ${expected_vcd}${NC}"
    fi
    
    echo -e "📝 ${GREEN}Log files saved successfully${NC}"
    echo -e "🎯 ${GREEN}TEST PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    
    return 0
}

# =============================================================================
# TEST DEFINITIONS ARRAY
# =============================================================================

# Define all tests in a structured array format
declare -a TESTBENCH_SUITE=(
    # Format: "category|name|file|dependencies|output_name|expected_vcd"
    
    # Basic ALU Component Tests
    "Basic_ALU_Components|Sequential Shifter|Testing_Results/BasicTestBenches/seq_shifter_tb.v|AirthmeticLogicModules/GateLevelModules/hardwareUnits.v|seq_shifter_test|seq_shifter_comprehensive.vcd"
    
    "Basic_ALU_Components|Sequential Multiplier|Testing_Results/BasicTestBenches/seq_unsigned_multiplier_tb.v|AirthmeticLogicModules/GateLevelModules/hardwareUnits.v|mult_test|seq_unsigned_multiplier_comprehensive.vcd"
    
    "Basic_ALU_Components|Comprehensive ALU|Testing_Results/BasicTestBenches/ALU_comprehensive_tb.v|Modules/ALU.v AirthmeticLogicModules/basicUnits.v|alu_comp_test|ALU_comprehensive.vcd"
    
    "Basic_ALU_Components|Implementation Comparison|Testing_Results/BasicTestBenches/implementation_comparison_tb.v|AirthmeticLogicModules/basicUnits.v AirthmeticLogicModules/GateLevelModules/hardwareUnits.v|impl_comp_test|implementation_comparison.vcd"
    
    "Basic_ALU_Components|CPU System|Testing_Results/BasicTestBenches/cpu_tb.v|Modules/CPU.v Modules/ALU.v Modules/ControlUnit.v Modules/ProgramCounter.v Modules/RegisterFile.v AirthmeticLogicModules/basicUnits.v|cpu_test|cpu_comprehensive.vcd"
    
    # Cache Memory System Tests  
    "Cache_Memory_Systems|Instruction Cache|Testing_Results/CacheTestbenches/instruction_cache_tb.v|CacheMemory/instructionCache.v CacheMemory/instructionMem.v|inst_cache_test|instruction_cache_comprehensive.vcd"
    
    "Cache_Memory_Systems|Data Cache|Testing_Results/CacheTestbenches/data_cache_tb.v|CacheMemory/dataMemCache.v CacheMemory/dataMemory.v|data_cache_test|data_cache_comprehensive.vcd"
    
    "Cache_Memory_Systems|Integrated Cache System|Testing_Results/CacheTestbenches/cache_integration_tb.v|CacheMemory/instructionCache.v CacheMemory/instructionMem.v CacheMemory/dataMemCache.v CacheMemory/dataMemory.v|cache_system_test|cache_integration_system.vcd"
)

# =============================================================================
# MAIN EXECUTION FUNCTION
# =============================================================================

main() {
    echo "=============================================================================="
    echo -e "${PURPLE}🚀 COMPREHENSIVE PROCESSOR TESTBENCH RUNNER - ROBUST VERSION${NC}"
    echo "Automated Testing Suite with Timeout Protection and Error Handling"
    echo "=============================================================================="
    echo -e "📊 ${CYAN}Configured Tests: ${#TESTBENCH_SUITE[@]}${NC}"
    echo -e "⏰ ${CYAN}Timeouts: Compile=${COMPILE_TIMEOUT}s, Simulation=${SIMULATION_TIMEOUT}s, Total=${MAX_SCRIPT_RUNTIME}s${NC}"
    echo "=============================================================================="
    
    # Setup directories
    setup_directories
    
    # Process each test
    local current_category=""
    
    for test_def in "${TESTBENCH_SUITE[@]}"; do
        # Parse test definition
        IFS='|' read -ra TEST_PARTS <<< "$test_def"
        local category="${TEST_PARTS[0]}"
        local name="${TEST_PARTS[1]}"
        local file="${TEST_PARTS[2]}"
        local deps="${TEST_PARTS[3]}"
        local output="${TEST_PARTS[4]}"
        local vcd="${TEST_PARTS[5]}"
        
        # Print category header if changed
        if [ "$category" != "$current_category" ]; then
            current_category="$category"
            echo ""
            echo -e "${PURPLE}════════════════════════════════════════════════════════════════════════════════${NC}"
            echo -e "${PURPLE}🧮 ${category//_/ } TESTBENCH SUITE${NC}"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════════════════════════${NC}"
        fi
        
        # Run the test
        run_testbench "$category" "$name" "$file" "$deps" "$output" "$vcd"
        
        # Check for timeout after each test
        check_script_timeout
    done
    
    # Generate final report
    generate_final_report
}

# =============================================================================
# FINAL REPORT GENERATION
# =============================================================================

generate_final_report() {
    local end_time=$(date +%s)
    local execution_time=$((end_time - SCRIPT_START_TIME))
    
    echo ""
    echo -e "${PURPLE}=============================================================================="
    echo -e "� COMPREHENSIVE TESTBENCH EXECUTION SUMMARY"
    echo -e "==============================================================================${NC}"
    echo ""
    
    # Execution Statistics
    echo -e "${GREEN}📊 EXECUTION STATISTICS:${NC}"
    echo -e "   • Total tests configured: ${CYAN}${#TESTBENCH_SUITE[@]}${NC}"
    echo -e "   • Tests executed: ${CYAN}$TOTAL_TESTS${NC}"
    echo -e "   • Tests passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "   • Tests failed: ${RED}$FAILED_TESTS${NC}"
    echo -e "   • Tests skipped: ${YELLOW}$SKIPPED_TESTS${NC}"
    
    if [ $TOTAL_TESTS -gt 0 ]; then
        local success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
        echo -e "   • Success rate: ${YELLOW}${success_rate}%${NC}"
    fi
    
    echo -e "   • Total execution time: ${PURPLE}${execution_time}s${NC}"
    
    # File Structure
    echo ""
    echo -e "${GREEN}� GENERATED FILES:${NC}"
    echo -e "${CYAN}Testing_Results/${NC}"
    echo -e "├── ${YELLOW}gtkwave_files/     ${NC}# VCD waveform files"
    echo -e "├── ${YELLOW}simulation_logs/   ${NC}# Compilation and simulation logs"  
    echo -e "└── ${YELLOW}executables/       ${NC}# Compiled testbench binaries"
    
    # List actual generated VCD files
    echo ""
    echo -e "${GREEN}� AVAILABLE WAVEFORM FILES:${NC}"
    if ls Testing_Results/gtkwave_files/*.vcd >/dev/null 2>&1; then
        for vcd_file in Testing_Results/gtkwave_files/*.vcd; do
            local basename=$(basename "$vcd_file")
            echo -e "   • ${basename}"
        done
    else
        echo -e "   ${YELLOW}No VCD files generated${NC}"
    fi
    
    # GTKWave Commands
    echo ""
    echo -e "${GREEN}🎮 GTKWAVE ANALYSIS COMMANDS:${NC}"
    if ls Testing_Results/gtkwave_files/*.vcd >/dev/null 2>&1; then
        for vcd_file in Testing_Results/gtkwave_files/*.vcd; do
            echo -e "   gtkwave $vcd_file"
        done
    fi
    
    # Documentation Reference
    echo ""
    echo -e "${GREEN}📖 DOCUMENTATION:${NC}"
    echo -e "   • Detailed analysis guide: ${CYAN}TESTBENCH_USAGE_GUIDE.md${NC}"
    echo -e "   • Simulation logs: ${CYAN}Testing_Results/simulation_logs/${NC}"
    echo -e "   • Troubleshooting: Check individual log files for errors"
    
    # Final Status
    echo ""
    if [ $FAILED_TESTS -eq 0 ] && [ $SKIPPED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL TESTBENCHES COMPLETED SUCCESSFULLY!${NC}"
        echo -e "${GREEN}Ready for comprehensive GTKWave analysis.${NC}"
    elif [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${YELLOW}⚠️  All executed tests passed, but some were skipped.${NC}"
        echo -e "${YELLOW}Check for missing dependencies.${NC}"
    else
        echo -e "${YELLOW}⚠️  Some testbenches failed or were skipped.${NC}"
        echo -e "${YELLOW}Review simulation logs before proceeding with analysis.${NC}"
    fi
    
    echo ""
    echo -e "${PURPLE}=============================================================================="
    echo -e "🏁 TESTBENCH RUNNER COMPLETED"
    echo -e "==============================================================================${NC}"
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Validate environment
if ! command -v iverilog >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: iverilog not found. Please install Icarus Verilog.${NC}"
    exit 1
fi

if ! command -v vvp >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: vvp not found. Please install Icarus Verilog.${NC}"
    exit 1
fi

if ! command -v timeout >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: timeout command not found. Please install coreutils.${NC}"
    exit 1
fi

# Run main function
main "$@"

# Script completion
exit 0