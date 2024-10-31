`include "defines2.sv"

module decoder(
    input [31:0] instruction,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output [31:0] imm,
    output [6:0] funct7,
    output [2:0] funct3,
    output [5:0] opcode,
    output [2:0] instr_type
);

    //OUTPUT
    assign opcode = instr[6:0];
    assign funct7 = instr[31:25];
    assign funct3 = instr[14:12];
    assign rd     = instr[11:7];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];

    wire instr_ALU     = (opcode == `OPCODE_ALU);
    wire instr_ALU_IMM = (opcode == `OPCODE_ALU_IMM);
    wire instr_BRANCH  = (opcode == `OPCODE_BRANCH);
    wire instr_STORE   = (opcode == `OPCODE_STORE);
    wire instr_LOAD    = (opcode == `OPCODE_LOAD);
    wire instr_JUMP    = (opcode == `OPCODE_JUMP);
    wire instr_AUIPC   = (opcode == `OPCODE_AUIPC);
    wire instr_LUI     = (opcode == `OPCODE_LUI);
    wire instr_NOP     = (opcode == `OPCODE_NOP);


    wire instr_R_type  = instr_ALU;
    wire instr_I_type  = instr_LOAD || instr_ALU_IMM;
    wire instr_S_type  = instr_STORE;
    wire instr_B_type  = instr_BRANCH;
    wire instr_J_type  = instr_JUMP;
    wire instr_U_type  = instr_AUIPC || instr_LUI;

    assign instr_type = (instr_R_type && funct7 == `MUL_FUNCT7) ? `INSTR_TYPE_MUL : ((instr_R_type && funct7 != `MUL_FUNCT7) || instr_AUIPC || instr_ALU_IMM || instr_NOP) ? `INSTR_TYPE_ALU : (instr_LOAD || instr_LUI) ? `INSTR_TYPE_LOAD : instr_STORE ? `INSTR_TYPE_STORE : `INSTR_TYPE_NO_WB;

    wire[`WORD_SIZE-1:0] I_imm = {{21{instr[31]}}, instr[30:20]};
    wire[`WORD_SIZE-1:0] S_imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
    wire[`WORD_SIZE-1:0] B_imm = {{20{instr[31]}}, instr[7],     instr[30:25], instr[11:8],  1'b0};
    wire[`WORD_SIZE-1:0] U_imm = {instr[31],       instr[30:12], {12{1'b0}}};
    wire[`WORD_SIZE-1:0] J_imm = {{12{instr[31]}}, instr[19:12], instr[20],    instr[30:21], 1'b0};

    assign imm = (instr_I_type) ? I_imm :
		 (instr_S_type) ? S_imm :
		 (instr_B_type) ? B_imm :
		 (instr_U_type) ? U_imm : J_imm;

endmodule
