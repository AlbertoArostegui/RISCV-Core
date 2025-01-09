
`ifndef DEFINES
`define DEFINES

`define WORD_SIZE 32

`define OPCODE_ALU      7'b0110011
`define OPCODE_ALU_IMM  7'b0010011
`define OPCODE_BRANCH   7'b1100011
`define OPCODE_STORE    7'b0100011
`define OPCODE_LOAD     7'b0000011
`define OPCODE_JUMP     7'b1101111
`define OPCODE_AUIPC    7'b0010111
`define OPCODE_LUI      7'b0110111
`define OPCODE_NOP      7'b0000000
`define OPCODE_SYSTEM   7'b1110011

/* alu funct3 */
`define OR_FUNCT3       3'b110 
`define AND_FUNCT3      3'b111 
`define ADD_FUNCT3      3'b000
`define ADDI_FUNCT3     3'b000 
`define SLLI_FUNCT3		3'b001
`define SRLI_FUNCT3		3'b101

/* branch funct3 */
`define BEQ_FUNCT3      3'b000
`define BNE_FUNCT3		3'b010
`define BLT_FUNCT3      3'b100
`define BGE_FUNCT3      3'b101

/* privileged funct3 */
`define IRET_FUNCT3     3'b000
`define TLBWRITE_FUNCT3 3'b111
`define MOVRM_FUNCT3    3'b001

`define SUB_FUNCT7      7'b0100000
`define MUL_FUNCT7      7'b0000001
`define ADD_OR_AND_FUNCT7   7'b0000000




`define CACHE_LINE_SIZE 128
`define CACHE_N_LINES   4
`define CACHE_ASSOCIATIVITY (0)
`define CACHE_DELAY_CYCLES 5
`define OFFSET_SIZE $clog2(`CACHE_LINE_SIZE / 8)

/* WORD_SIZE - line index bits - byte offset bits. Associativity increases tag size */
`define TAG_SIZE (`WORD_SIZE - $clog2(`CACHE_N_LINES) - `OFFSET_SIZE + `CACHE_ASSOCIATIVITY)

`define MEM_DELAY_CYCLES 10
`define MEM_SIZE (1 << 18)

`define INSTR_TYPE_ALU      3'b000
`define INSTR_TYPE_MUL      3'b001
`define INSTR_TYPE_NO_WB    3'b010
`define INSTR_TYPE_STORE    3'b011
`define INSTR_TYPE_LOAD     3'b100
`define INSTR_TYPE_IRET     3'b110
`define INSTR_TYPE_MOVRM    3'b111
`define INSTR_TYPE_TLBWRITE 3'b101
`define INSTR_TYPE

`define EXCEPTION_TYPE_ILLEGAL 3'b010
`define EXCEPTION_TYPE_PRIV    3'b100
`define EXCEPTION_TYPE_DTLBMISS 3'b101
`define EXCEPTION_TYPE_ITLBMISS 3'b001

`define STORE_BUFFER_ENTRIES	4

`endif


