# RISC V PROCESSOR
The following are the intended features to be implemented on this processor.


- [ ] iTLB
- [ ] dTLB
- [ ] iCache            (Almost)
- [ ] dCache            (Almost)
- [ ] Branch Prediction
- [X] Bypass ALU
- [X] Bypass memory
- [ ] ptw
- [X] LB, LH, LW
- [X] SB, SH, SW
- [ ] Store Buffer
- [ ] Common Memory
- [ ] ROB
- [ ] iret
- [ ] csrrw
- [ ] exceptions
- [X] ISA
- [ ] TLB miss
- [ ] TLB write
- [ ] sb drain
- [ ] 5 stage multiplication
- [ ] bypass from sb
- [ ] Performance data

# CURRENT IMPLEMENTATION DIAGRAM
This diagram shows (more or less) the current implementation of the processor, it will be updated along with the processor.

<img width="1510" alt="Screenshot 2024-12-02 at 22 59 33" src="https://github.com/user-attachments/assets/e81c719a-5c4d-4d0c-8e6b-a1caeaa5774e">


To run the tests, from src directory:
```bash
./run_test.sh testbench.sv
```
The core testbench can be used to debug the whole core, it contains a lot of displayed information of each stage as they execute
