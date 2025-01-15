# RISC V PROCESSOR
The following are the intended features to be implemented on this processor. It currently works, although it would benefit from some more debugging


- [X] iTLB
- [X] dTLB
- [X] iCache         
- [X] dCache           
- [ ] Branch Prediction
- [X] Bypass ALU
- [X] Bypass memory
- [X] Page table walker (TLB Write)
- [X] LB, LH, LW
- [X] SB, SH, SW
- [X] Store Buffer
- [X] Common Memory
- [X] ROB
- [X] iret
- [X] csrrw
- [X] exceptions
- [X] ISA
- [X] TLB miss
- [X] TLB write
- [X] sb drain
- [X] 5 stage multiplication
- [X] bypass from sb
- [X] Performance data

# CODE STRUCTURE
The top module is SoC.sv, in which both core and memory modules are instantiated. Each stage has one module file (stageX_name.sv) and each set of pipeline registers has another one (registersX_name.sv). All the stages and registers modules are instantiated in the core.sv file. All combinational logic is inside its respective stage module.

Each module has a set of inputs and outputs, which are grouped (in the sense of blank or contiguous lines) by its function within the processor, usually with a comment. 
Wires that connect two modules inside the core are declared before the first of the two modules.

# TESTING
To run the tests, from src directory:
```bash
./run_test.sh testbench.sv > output.txt
```
The script will compile the testbench with icarus Verilog and run it, leaving the executable and thew waveform in the Build directory
The core testbench can be used to debug the whole core, it contains a lot of displayed information of each stage as they execute. I would recommend to redirect the std output to a text file, since the outputted information is abundant
