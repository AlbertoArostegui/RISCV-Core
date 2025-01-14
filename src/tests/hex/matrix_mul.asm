i_loop:
    li x1, 0                ; 0x50 i = 0 (outer loop counter)
j_loop:
    li x2, 0                ; 0x54 j = 0 (middle loop counter)
    li x18, 0               ; 0x58 c[i][j] = 0 (accumulator for the dot product)
k_loop:
    li x7, 0                ; 0x5C k = 0 (inner loop counter)
    li x4, 128              ; 0x60 Set the matrix dimension (128)

    bge x7, x4, end_k       ; 0x64 if k >= 128, exit the inner loop

    li x8, 992              ; 0x68 Load base address of matrix a
    mul x9, x1, x4          ; 0x6C Calculate row offset: i * 128
    add x10, x9, x7         ; 0x70 Add column offset: i * 128 + k
    slli x10, x10, 2        ; 0x74 Convert to byte offset: (i * 128 + k) * 4
    add x8, x8, x10         ; 0x78 Address of a[i][k]
    lw x11, 0(x8)           ; 0x7C Load a[i][k]

    li x12, 66528           ; Load base address of matrix b
    mul x13, x7, x4         ; Calculate row offset: k * 128
    add x14, x13, x2        ; Add column offset: k * 128 + j
    slli x14, x14, 2        ; Convert to byte offset: (k * 128 + j) * 4
    add x12, x12, x14       ; Address of b[k][j]
    lw x15, 0(x12)          ; Load b[k][j]

    mul x16, x11, x15       ; Compute product: a[i][k] * b[k][j]
    add x18, x18, x16       ; Accumulate into c[i][j]

    addi x7, x7, 1          ; k++
    j k_loop                ; Repeat inner loop
end_k:
    li x3, 132064           ; Load base address of matrix c
    mul x5, x1, x4          ; Calculate row offset: i * 128
    add x6, x5, x2          ; Add column offset: i * 128 + j
    slli x6, x6, 2          ; Convert to byte offset: (i * 128 + j) * 4
    add x3, x3, x6          ; Address of c[i][j]
    sw x18, 0(x3)           ; Store accumulated result in c[i][j]

    addi x2, x2, 1          ; j++
    blt x2, x4, j_loop      ; Repeat middle loop if j < 128

    addi x1, x1, 1          ; i++
    blt x1, x4, i_loop      ; Repeat outer loop if i < 128