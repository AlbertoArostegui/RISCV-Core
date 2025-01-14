addi x1, x0, 1000 ; Load base address of the array
addi x10, x0, 128 ; Load limit
addi x11, x0, 0 ; Init sum to 0
addi x12, x0, 0 ; i

loop:
    lw x2, 0(x1) ; Load value from array
    addi x12, x12, 1 ; Increment i
    addi x1, x1, 4 ; Move to next value
    add, x11, x11, x2 ; Add value to sum
    blt x12, x10, loop ; Loop until i >= limit