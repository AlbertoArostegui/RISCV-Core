# RISC V PROCESSOR
The following are the intended features to be implemented on this processor.


- [ ] iTLB
- [ ] dTLB
- [ ] iCache
- [ ] dCache
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
- [ ] ISA
- [ ] TLB miss
- [ ] TLB write
- [ ] sb drain
- [ ] 5 stage multiplication
- [ ] bypass from sb
- [ ] Performance data

To run the tests, from src directory:
```bash
./run_test.sh testbench.sv
```
The core testbench can be used to debug the whole core, it contains a lot of displayed information of each stage as they execute
