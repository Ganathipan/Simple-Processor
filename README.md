# CO224 Lab 5 - Task 5 Project Structure and Usage Guide

**Authors:** S. Ganathipan [E/21/148], K. Jarshigan [E/21/188]  
**Date:** 2025-06-22  
**Institution:** Computer Engineering Department, Faculty of Engineering, University of Peradeniya (UOP)
  
**GitHub Repository:** https://github.com/Ganathipan/Simple-Processor/tree/main

---

## Overview
This project implements a complete 8-bit RISC processor in Verilog HDL for CO224 Lab exercises. The processor features a modular design with cache memory support, realistic timing characteristics, and includes both high-level behavioral models and gate-level implementations. The design separates hardware-level modules, processor components, and memory hierarchy, supporting both unit and system-level testing for comprehensive learning and verification.

## Project Architecture
- **8-bit data width** with 32-bit instruction encoding
- **8 general-purpose registers** (R0-R7)  
- **RISC-style instruction set** with uniform encoding
- **Direct-mapped cache hierarchy** (instruction and data caches)
- **Realistic memory timing** with proper bus protocols
- **Comprehensive instruction set** including arithmetic, logic, memory, and control flow operations

## Comprehensive Code File Explanations

### 📁 **AirthmeticLogicModules/**

#### **basicUnits.v**
**Purpose**: Contains basic arithmetic and logic operation modules that serve as building blocks for the ALU.

**Key Modules**:
- **`fwdUnit`**: Simple forward/pass-through module with 1ns delay for MOV and LOADI operations
- **`addUnit`**: 8-bit addition with 2ns delay supporting both addition and subtraction
- **`andUnit`**: Bitwise AND operation with 1ns delay  
- **`orUnit`**: Bitwise OR operation with 1ns delay
- **`mulUnit`**: Signed 8-bit multiplication using shift-and-add algorithm with enable control
- **`shifterUnit`**: Universal shifter supporting:
  - Logical shift left (00): `DATA1 << DATA2[3:0]`
  - Logical shift right (01): `DATA1 >> DATA2[3:0]` 
  - Arithmetic shift right (10): Sign-extended right shift
  - Rotate right (11): Circular right rotation

**Implementation Details**: These modules use behavioral Verilog with realistic propagation delays. The multiplier implements the shift-and-add algorithm in a combinational always block, while the shifter uses a for-loop to perform iterative shifting based on the control bits in DATA2[5:4].

#### **GateLevelModules/hardwareUnits.v**
**Purpose**: Gate-level implementations demonstrating how complex operations are built from basic logic gates.

**Key Modules**:
- **`gate_level_seq_shifter`**: 
  - FSM-controlled sequential shifter using only NAND and AND gates
  - States: IDLE → shift operations → DONE
  - Manual bit-by-bit shifting logic without high-level operators
  - Supports all shift types with proper control decoding

- **`seq_unsigned_multiplier`**: 
  - Gate-level 8-bit multiplier using shift-and-add algorithm
  - Manual 16-bit full adder implementation using basic gates
  - Sequential operation over 8 clock cycles
  - Demonstrates digital circuit construction principles

**Educational Value**: Shows the relationship between high-level HDL constructs and actual hardware implementation, bridging the gap between behavioral modeling and physical circuit realization.

### 📁 **Modules/** - Core Processor Components

#### **CPU.v**
**Purpose**: Top-level CPU module integrating all processor components into a complete processing unit.

**Architecture Overview**:
```
[Instruction Cache] → [Control Unit] → Control Signals
        ↓                   ↓
[Program Counter] → [Register File] → [ALU] → [Data Cache]
        ↑                   ↑         ↓
[Branch Logic] ← [Zero Flag] ← [ALU Result]
```

**Key Integration Points**:
- **Instruction Pipeline**: PC → Instruction Fetch → Decode → Execute
- **Data Path**: Register File → ALU → Write-back/Memory
- **Control Flow**: Branch/Jump logic with zero flag dependency
- **Memory Interface**: Separate instruction and data cache connections
- **Hazard Handling**: BUSYWAIT signals for proper cache synchronization

**Signal Flow**: The module implements a classic RISC pipeline with proper stall handling during cache misses, ensuring data integrity and correct instruction sequencing.

#### **ALU.v**
**Purpose**: Central arithmetic and logic unit performing all computational operations.

**Operation Encoding (ALUOP)**:
- `000`: Forward (MOV, LOADI)
- `001`: Add/Subtract (controlled by SIGN_CONTROL)
- `010`: Bitwise AND
- `011`: Bitwise OR  
- `100`: Multiplication (8-bit signed)
- `101`: Shift/Rotate operations

**Design Features**:
- **Modular Architecture**: Each operation implemented in separate functional units
- **Enable Signals**: Conditional operation for complex units (MUL, SHIFT)
- **Zero Flag Generation**: Critical for branch instruction implementation
- **Timing Considerations**: Different operations have different propagation delays

**Implementation**: Uses a case statement for operation selection with instantiated submodules, allowing for easy testing and verification of individual operations.

#### **ControlUnit.v**
**Purpose**: Instruction decoder generating all necessary control signals for datapath operation.

**Supported Instruction Set**:

| Category | Instructions | OpCode | Description |
|----------|-------------|--------|-------------|
| **Arithmetic** | ADD, SUB, MUL | 0x02, 0x03, 0x0C | Basic arithmetic operations |
| **Logic** | AND, OR | 0x04, 0x05 | Bitwise logical operations |
| **Data Movement** | MOV, LOADI | 0x01, 0x00 | Register-register and immediate transfers |
| **Memory Access** | LWD, LWI, SWD, SWI | 0x08-0x0B | Load/store with direct and immediate addressing |
| **Control Flow** | J, BEQ, BNE | 0x06, 0x07, 0x0E | Unconditional and conditional branches |
| **Bit Operations** | SHIFT | 0x0D | Universal shift/rotate operations |

**Control Signal Generation**:
- **ALUOP[2:0]**: Selects ALU operation mode
- **WRITE_ENABLE**: Controls register file write operations  
- **SIGN_CONTROL**: Enables 2's complement for subtraction/comparison
- **OPERAND_CONTROL**: Selects between register and immediate operands
- **BRANCH_CONTROL[1:0]**: Branch type selection (none/BEQ/BNE)
- **Memory Controls**: READ_DATA_MEM, WRITE_DATA_MEM for cache interface

#### **ProgramCounter.v**
**Purpose**: Manages instruction sequencing with branch and jump support.

**Components**:
- **`ProgramCounter`**: Simple clocked register with reset capability
- **`pcIncrementer`**: Complex branch logic implementation

**Branch/Jump Logic**:
```verilog
PC_OUT = JUMP ? offset : 
         (BRANCH == 2'b01 && ZERO) ? offset :     // BEQ taken
         (BRANCH == 2'b10 && !ZERO) ? offset :   // BNE taken  
         PC + 4;                                  // Sequential
```

**Address Calculation**: Branch offset uses sign extension: `{{22{BRANCH_ADDRESS[7]}}, BRANCH_ADDRESS, 2'b00}` for proper 32-bit addressing with word alignment.

**Pipeline Integration**: BUSYWAIT handling ensures correct PC updates during cache misses, preventing instruction skipping or duplication.

#### **RegisterFile.v**
**Purpose**: High-performance register storage with dual-port read capability.

**Specifications**:
- **8 registers × 8 bits** (R0-R7)
- **Dual read ports**: Simultaneous access to two registers
- **Single write port**: One register update per cycle
- **Asynchronous read**: 2ns access time
- **Synchronous write**: Clock-edge triggered with enable

**Interface Design**: Standard RISC register file interface supporting the typical two-source-one-destination instruction format used throughout the processor.

### 📁 **CacheMemory/** - Memory Hierarchy

#### **dataMemCache.v**
**Purpose**: High-performance data cache implementing modern memory hierarchy principles.

**Cache Specifications**:
- **Organization**: Direct-mapped, 8 lines × 4 bytes per line
- **Address Mapping**: 
  - Tag: `address[7:5]` (3 bits)
  - Index: `address[4:2]` (3 bits)  
  - Offset: `address[1:0]` (2 bits)
- **Write Policy**: Write-back with dirty bit tracking
- **Replacement**: Direct-mapped (no choice needed)

**FSM States and Operations**:
```
IDLE: Hit/miss detection and immediate service for hits
  ├─→ WRITE_BACK: Evict dirty cache line to memory
  └─→ FETCH: Load new cache line from memory
```

**Performance Features**:
- **1ns hit latency** for immediate data access
- **Automatic write-back** of modified cache lines
- **Proper bus protocols** with handshaking via busywait signals

#### **instructionCache.v**
**Purpose**: Optimized instruction cache for high-bandwidth instruction fetching.

**Design Characteristics**:
- **Block Size**: 16 bytes (4 instructions) per cache line
- **Capacity**: 8 blocks total (128 bytes)
- **Fetch Strategy**: Block-level loading from main memory
- **Access Pattern**: Optimized for sequential instruction execution

**Implementation Details**: Uses artificial timing delays to simulate realistic cache behavior while maintaining proper synchronization with the CPU pipeline.

#### **Memory Modules (dataMemory.v, instructionMem.v)**
**Purpose**: Main memory simulation with realistic DRAM-like characteristics.

**Timing Model**:
- **40ns access latency**: Simulates realistic DRAM timing
- **Block transfers**: 4-byte (data) and 16-byte (instruction) blocks  
- **Busywait protocol**: Proper handshaking for multi-cycle operations

**Memory Organization**: Byte-addressable with block-aligned access patterns matching cache line sizes for optimal performance.

### 📁 **SimpleComputer/** - System Integration

#### **simpleComputer.v**
**Purpose**: Complete computer system integrating CPU, caches, and main memory.

**System Architecture**:
```
CPU ←→ Instruction Cache ←→ Instruction Memory
 ↕
Data Cache ←→ Data Memory
```

**Bus Protocol Implementation**: All memory interfaces use standardized handshaking with read/write enables, address buses, data buses, and busywait signals for proper multi-cycle operation coordination.

#### **CO224Assembler_Modified.c**
**Purpose**: Complete assembler toolchain for high-level programming support.

**Features**:
- **Instruction Parsing**: Handles all processor instruction formats
- **Error Detection**: Syntax checking and validation
- **Address Resolution**: Automatic encoding of registers and immediates  
- **Output Generation**: Binary machine code compatible with memory initialization

**Instruction Format Support**:
- **R-Type**: `operation dest, src1, src2` (e.g., `add 3 1 2`)
- **I-Type**: `operation dest, src, #immediate` (e.g., `loadi 5 0x1A`)
- **J-Type**: `operation #address` (e.g., `j 0x10`)

### 📁 **Testing_Results/** - Verification Infrastructure

#### **cpu_tb.v**
**Purpose**: Comprehensive system-level testbench for processor verification.

**Testing Capabilities**:
- **Instruction Memory Loading**: From `.mem` files generated by assembler
- **Waveform Generation**: Complete signal tracing for debugging
- **Register Monitoring**: Real-time observation of all register contents
- **Cycle-by-cycle Analysis**: Detailed execution trace with PC and instruction display

**Verification Strategy**: Combines automated testing with visual waveform analysis, enabling both functional verification and performance analysis of the complete processor system.

## Complete Development Workflow

### **Phase 1: Assembly Programming and Code Generation**

#### 1.1 Navigate to the Project Directory
```bash
cd /home/ganathipan/CO224_CA/VerilogHDL/ProcessorBuild/
```

#### 1.2 Compile the Assembler Toolchain  
```bash
cd SimpleComputer/InstructionMemoryCompiler/
gcc CO224Assembler_Modified.c -o CO224Assembler
```
**Purpose**: Creates the executable assembler that converts human-readable assembly code into processor-compatible machine code.

#### 1.3 Write and Assemble Programs
```bash
# Create your assembly program (example: test_program.s)
./CO224Assembler test_program.s
```
**Output**: Generates `test_program.s.machine` containing binary machine code ready for processor execution.

**Assembly Language Example**:
```assembly
// Sample program demonstrating various instructions
loadi 1 0x0A        // Load immediate value 10 into register 1
loadi 2 0x05        // Load immediate value 5 into register 2  
add 3 1 2           // Add R1 + R2, store result in R3
mul 4 3 2           // Multiply R3 * R2, store in R4
sll 5 4 #2          // Shift R4 left by 2 positions, store in R5
swd 5 0x20          // Store R5 to memory address 0x20
j 0x00              // Jump back to beginning
```

### **Phase 2: Hardware Module Verification**

#### 2.1 Test Basic Arithmetic/Logic Units
```bash
# Test individual ALU components
cd AirthmeticLogicModules/
iverilog -o basic_units_test basicUnits.v -D TESTBENCH
vvp basic_units_test

# Verify gate-level implementations  
cd GateLevelModules/
iverilog -o shifter_test hardwareUnits.v seq_shifter_tb.v
vvp shifter_test
gtkwave seq_shifter.vcd &

iverilog -o multiplier_test hardwareUnits.v seq_unsigned_multiplier_tb.v  
vvp multiplier_test
gtkwave seq_unsigned_multiplier.vcd &
```
**Purpose**: Validates the correctness of fundamental computational units before integration into the processor.

#### 2.2 Test Core Processor Modules
```bash
cd ../Modules/

# Test ALU functionality
iverilog -o alu_test ALU.v ../AirthmeticLogicModules/basicUnits.v
vvp alu_test

# Test register file operations
iverilog -o regfile_test RegisterFile.v -D TESTBENCH  
vvp regfile_test

# Test control unit instruction decoding
iverilog -o control_test ControlUnit.v -D TESTBENCH
vvp control_test

# Test program counter and branching
iverilog -o pc_test ProgramCounter.v -D TESTBENCH
vvp pc_test
```
**Purpose**: Ensures each processor component functions correctly in isolation before system integration.

### **Phase 3: Cache and Memory System Verification** 

#### 3.1 Test Memory Hierarchy Components
```bash
cd ../CacheMemory/

# Test data cache functionality
iverilog -o dcache_test dataMemCache.v dataMemory.v -D TESTBENCH
vvp dcache_test

# Test instruction cache performance  
iverilog -o icache_test instructionCache.v instructionMem.v -D TESTBENCH
vvp icache_test

# Generate cache performance analysis
gtkwave dcache_test.vcd &
gtkwave icache_test.vcd &
```
**Purpose**: Validates cache hit/miss behavior, write-back policies, and memory timing characteristics.

### **Phase 4: System Integration and Full Processor Testing**

#### 4.1 Complete System Simulation
```bash
cd ../SimpleComputer/

# Integrate all components for full system test
iverilog -o system_test simpleComputer.v \
    ../Modules/CPU.v \
    ../Modules/ALU.v \
    ../Modules/ControlUnit.v \
    ../Modules/ProgramCounter.v \
    ../Modules/RegisterFile.v \
    ../AirthmeticLogicModules/basicUnits.v \
    ../CacheMemory/dataMemCache.v \
    ../CacheMemory/instructionCache.v \
    ../CacheMemory/dataMemory.v \
    ../CacheMemory/instructionMem.v

vvp system_test
```

#### 4.2 Load and Run Assembly Programs
```bash  
cd ../Testing_Results/

# Run comprehensive CPU testbench with your programs
iverilog -o cpu_complete_test cpu_tb.v \
    ../SimpleComputer/simpleComputer.v \
    [... all other module dependencies ...]

# Load instruction memory and execute
cp ../SimpleComputer/InstructionMemoryCompiler/test_program.s.machine ./instr_mem.mem
vvp cpu_complete_test

# Analyze execution waveforms
gtkwave cpu_wavedata.vcd &
```

### **Phase 5: Performance Analysis and Debugging**

#### 5.1 Waveform Analysis Workflow
```bash
# Generate comprehensive waveforms for debugging
gtkwave cpu_wavedata.vcd &

# Key signals to monitor:
# - CPU.PC_OUT: Instruction address progression  
# - CPU.INSTRUCTION: Current instruction being executed
# - CPU.u_regfile.reg_array[*]: Register contents over time
# - CPU.ALURESULT: ALU computation results
# - CPU.BUSYWAIT: Cache miss stall conditions
# - System cache hit/miss rates and memory access patterns
```

#### 5.2 Performance Metrics Collection
- **Cache Hit Rate**: Monitor cache access patterns in waveforms
- **Memory Bandwidth Utilization**: Analyze bus busy cycles  
- **Instruction Throughput**: Count completed instructions per cycle
- **Branch Prediction Accuracy**: Observe branch resolution timing
- **Pipeline Efficiency**: Measure stall cycles vs. productive cycles

### **Phase 6: Advanced Testing and Validation**

#### 6.1 Comprehensive Test Suite Execution
```bash  
# Run extended test programs covering all instruction types
./run_test_suite.sh

# Test cases should include:
# - Arithmetic operations (ADD, SUB, MUL)
# - Logic operations (AND, OR) 
# - Memory operations (LWD, LWI, SWD, SWI)
# - Control flow (J, BEQ, BNE)
# - Shift operations (SLL, SRL, SRA, ROR)
# - Cache stress tests (random memory access patterns)
# - Pipeline hazard scenarios
```

#### 6.2 Integration with Memory Files
- **Instruction Memory**: Store `.machine` files in `SimpleComputer/` directory
- **Data Memory**: Initialize with test data patterns for comprehensive testing  
- **Memory Hierarchy Validation**: Ensure proper cache-memory coherence

## Key Design Principles and Educational Philosophy

### **1. Hierarchical Modularity**
- **Bottom-Up Design**: From basic gates → functional units → processor components → complete system
- **Interface Standardization**: Consistent signal naming and timing across all modules
- **Independent Testability**: Each module can be verified in isolation before integration
- **Scalability**: Design patterns that can be extended for larger processors

### **2. Realistic System Modeling**
- **Authentic Timing**: Propagation delays matching real hardware characteristics
- **Memory Hierarchy**: Modern cache-based memory system with realistic latencies
- **Bus Protocols**: Industry-standard handshaking and flow control mechanisms
- **Performance Optimization**: Cache design principles for improved system performance

### **3. Educational Value Maximization**
- **Multiple Abstraction Levels**: From gate-level to behavioral modeling
- **Progressive Complexity**: Students can understand concepts at their current level
- **Visual Debugging**: Comprehensive waveform generation for signal analysis
- **Real-World Relevance**: Design patterns used in commercial processors

### **4. Verification and Quality Assurance**
- **Comprehensive Testing**: Unit tests for every module plus system-level integration tests
- **Automated Verification**: Testbenches with self-checking capabilities
- **Debugging Support**: Detailed signal monitoring and trace generation
- **Error Detection**: Both compile-time and runtime error checking

### **5. Tool Integration and Workflow**
- **Complete Toolchain**: From assembly language to hardware simulation
- **Standard File Formats**: Industry-compatible VCD files for waveform viewing
- **Cross-Platform Compatibility**: Works with standard Verilog simulators
- **Documentation Integration**: Code comments linked to overall system documentation

### **6. Performance and Optimization**
- **Cache Effectiveness**: Realistic cache hit/miss ratios and performance impact
- **Pipeline Efficiency**: Proper hazard detection and stall mechanisms
- **Memory Bandwidth**: Block-based transfers matching modern memory systems
- **Critical Path Analysis**: Timing optimization throughout the design

## Quick Start Example: Complete Development Cycle

### **Example 1: Simple Arithmetic Program**
```bash
# 1. Create assembly program (arithmetic_test.s)
cat > SimpleComputer/InstructionMemoryCompiler/arithmetic_test.s << EOF
// Simple arithmetic demonstration
loadi 1 0x0F        // Load 15 into R1
loadi 2 0x03        // Load 3 into R2  
add 3 1 2           // R3 = R1 + R2 = 18
sub 4 3 2           // R4 = R3 - R2 = 15
mul 5 4 2           // R5 = R4 * R2 = 45
sll 6 5 #2          // R6 = R5 << 2 = 180
EOF

# 2. Assemble to machine code
cd SimpleComputer/InstructionMemoryCompiler/
./CO224Assembler arithmetic_test.s

# 3. Run complete system simulation  
cd ../../Testing_Results/
cp ../SimpleComputer/InstructionMemoryCompiler/arithmetic_test.s.machine ./instr_mem.mem
iverilog -o complete_test cpu_tb.v ../SimpleComputer/simpleComputer.v [dependencies...]
vvp complete_test

# 4. Analyze results
gtkwave cpu_wavedata.vcd &
```

### **Example 2: Cache Performance Analysis**
```bash
# Create memory-intensive program to test cache behavior
cat > cache_test.s << EOF
loadi 1 0x00        // Base address
loadi 2 0x01        // Increment
loadi 3 0x10        // Loop counter

loop:
swd 1 1             // Store to memory[R1] (creates cache traffic)
add 1 1 2           // Increment address  
sub 3 3 2           // Decrement counter
bne loop            // Branch if not zero
EOF

# Assemble and run with cache monitoring
./CO224Assembler cache_test.s
# ... simulation commands ...
# Monitor cache hit/miss patterns in waveforms
```

### **Example 3: Control Flow Verification**  
```bash
# Test branching and jump instructions
cat > control_flow_test.s << EOF
loadi 1 0x05        // Test value
loadi 2 0x05        // Comparison value
loadi 3 0x00        // Result register

beq equal           // Branch if R1 == R2
loadi 3 0xFF        // Not equal path  
j end

equal:
loadi 3 0x01        // Equal path

end:
// R3 should contain 0x01 if branch taken correctly
EOF
```

## Advanced Features and Optimization

### **Custom Instruction Development**
The processor architecture supports easy instruction set extension:

1. **Add new opcode** to `ControlUnit.v`
2. **Implement operation** in `ALU.v` or create new functional unit
3. **Update assembler** in `CO224Assembler_Modified.c`  
4. **Create test cases** to verify functionality

### **Performance Tuning Guidelines**
- **Cache Optimization**: Adjust cache sizes in cache modules for different workloads
- **Pipeline Depth**: Modify pipeline stages for higher clock frequencies
- **Memory Latency**: Tune memory timing parameters for different memory types
- **Branch Prediction**: Implement advanced branch prediction for better performance

### **Debugging Best Practices**
1. **Start Simple**: Begin with single instruction tests
2. **Use Waveforms**: Always generate and analyze VCD files
3. **Monitor Key Signals**: Focus on PC, instruction, registers, and control signals
4. **Check Timing**: Verify setup/hold times and propagation delays
5. **Validate Incrementally**: Test each module before integration

### **Common Issues and Solutions**

| Problem | Symptoms | Solution |
|---------|----------|----------|
| **Cache Thrashing** | High miss rates, poor performance | Adjust cache size or associativity |
| **Pipeline Stalls** | Low instruction throughput | Check hazard detection logic |
| **Timing Violations** | Incorrect results, metastability | Review clock domains and delays |
| **Memory Coherence** | Data corruption | Validate cache write-back policies |
| **Branch Misprediction** | Performance degradation | Implement better prediction algorithms |

---

## Technical Support and Resources

### **File Structure Navigation**
- **Start Here**: `README.md` (this file) for overall project understanding
- **Hardware Basics**: `AirthmeticLogicModules/` for fundamental operations  
- **Core Design**: `Modules/` for main processor components
- **Memory System**: `CacheMemory/` for performance-critical memory hierarchy
- **System Integration**: `SimpleComputer/` for complete processor system
- **Verification**: `Testing_Results/` for comprehensive testing infrastructure

### **Learning Path Recommendations**
1. **Beginners**: Start with `basicUnits.v`, understand basic operations
2. **Intermediate**: Study `ALU.v` and `ControlUnit.v` for processor fundamentals  
3. **Advanced**: Analyze cache implementations and memory hierarchy
4. **Expert**: Modify and extend the instruction set or add new features

Each module contains extensive comments explaining design decisions, implementation details, and integration points. The modular architecture allows for independent study and modification of individual components without affecting the overall system stability.
