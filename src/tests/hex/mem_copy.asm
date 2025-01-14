    addi x1, x0, 992 ; 0x50 Load base address of the array
    addi x2, x0, 2000 ; 0x54 Load base address of the destination array          
    addi x3, x0, 128 ; 0x58 Load limit         
    addi x4, x0, 0 ; 0x5C i

loop_mem_set:
    addi x5, x0, 5 ; 0x60 Load constant 5 to store in memory 
    sw x5, 0(x1) ; 0x64 Store 5 in memory
    addi x1, x1, 4 ; 0x68 Move to next value
    addi x4, x4, 1 ; 0x6C Increment i
    blt x4, x3, loop_mem_set ; 0x70 Loop until i >= limit

    addi x1, x0, 992 ; 0x74 Load base address of the array
    addi x4, x0, 0 ; 0x78 Reset i

loop_mem_copy:
    lw x5, 0(x1) ; 0x7C Load value from array A
    addi x1, x1, 4 ; 0x80 Move to next value
    addi x4, x4, 1 ; 0x84 Increment i     
    sw x5, 0(x2) ; 0x88 Store value in array B
    addi x2, x2, 4 ; 0x8C Move to next value
    blt x4, x3, loop_mem_copy ; 0x90 Loop until i >= limit