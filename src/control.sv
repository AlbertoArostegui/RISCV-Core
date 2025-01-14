`include "defines.sv"
module control(
    input [31:0] in_instruction,

    //For EXECUTE STAGE (For Alu)
    output EX_alu_src,
    output [2:0] EX_alu_op,

    //For MEMORY STAGE
    output MEM_mem_write,
    output MEM_mem_read,
    output MEM_branch_inst,

    //For WRITE-BACK STAGE
    output WB_write_mem_to_reg,
    output WB_write_enable

);
//Control according to Patterson Hennessy

wire [6:0] opcode = in_instruction[6:0];

assign EX_alu_src = ((opcode == `OPCODE_LOAD) || (opcode == `OPCODE_STORE)); //Will be 1 if load or store --> Operand2 is imm
assign EX_alu_op = 3'b0;

assign MEM_mem_write = (opcode == `OPCODE_STORE);
assign MEM_mem_read = (opcode == `OPCODE_LOAD);
assign MEM_branch_inst = (opcode == `OPCODE_BRANCH);

assign WB_write_mem_to_reg = (opcode == `OPCODE_LOAD);
assign WB_write_enable = ((opcode == `OPCODE_RTYPE) || (opcode == `OPCODE_LOAD) || (opcode == `OPCODE_ALU_IMM) || (opcode == `OPCODE_LUI));

endmodule
