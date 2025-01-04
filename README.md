# RISC V PROCESSOR
The following are the intended features to be implemented on this processor.


- [ ] iTLB
- [ ] dTLB
- [X] iCache         
- [X] dCache           
- [ ] Branch Prediction
- [X] Bypass ALU
- [X] Bypass memory
- [ ] ptw
- [X] LB, LH, LW
- [X] SB, SH, SW
- [X] Store Buffer
- [X] Common Memory
- [X] ROB
- [ ] iret
- [ ] csrrw
- [ ] exceptions
- [X] ISA
- [ ] TLB miss
- [ ] TLB write
- [ ] sb drain
- [X] 5 stage multiplication
- [X] bypass from sb
- [ ] Performance data

# CURRENT IMPLEMENTATION DIAGRAM
This diagram shows (more or less) the current implementation of the processor, it will be updated along with the processor.

<img width="1510" alt="Screenshot 2024-12-02 at 22 59 33" src="https://github.com/user-attachments/assets/e81c719a-5c4d-4d0c-8e6b-a1caeaa5774e">

# CODE STRUCTURE
The top module is SoC.sv, in which both core and memory modules are instantiated. Each stage has one module file (stageX_name.sv) and each set of pipeline registers has another one (registersX_name.sv). All the stages and registers modules are instantiated in the core.sv file. All combinational logic is inside its respective stage module.

Each module has a set of inputs and outputs, which are grouped (in the sense of blank or contiguous lines) by its function within the processor, usually with a comment. 
Wires that connect two modules inside the core are declared before the first of the two modules.

# TESTING
To run the tests, from src directory:
```bash
./run_test.sh testbench.sv
```
The script will compile the testbench with icarus Verilog and run it, leaving the executable and thew waveform in the Build directory
The core testbench can be used to debug the whole core, it contains a lot of displayed information of each stage as they execute