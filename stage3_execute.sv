`include "alu.sv"

module stage_execute(
    input clk,
    input reset,

    //INPUT
    input [31:0] in_instruction,
    input [31:0] in_PC,

    //Alu
    input [31:0] in_rs1,
    input [31:0] in_rs2,
    input [31:0] in_immediate,

    //Alu control
    input in_alu_src,
    input in_alu_op,

    input [6:0] in_funct7,
    input [2:0] in_funct3,
    input [5:0] in_opcode,
    input [2:0] in_inst_type,

    //Passing by
    input [4:0] in_rd,

        //Control
    input in_mem_write,
    input in_mem_read,
    input in_branch_inst,

    input in_mem_to_reg,
    input in_write_enable,


    //OUTPUT
    output [31:0] out_alu_out,
    output [31:0] out_PC,
        //Control
    output out_branch_taken,

    output [4:0] out_rd,
    output out_mem_write,
    output out_mem_read,
    output out_branch_inst,
    output out_mem_to_reg,
    output out_write_enable
);

assign out_rd = in_rd;
assign out_mem_write = in_mem_write;
assign out_mem_read = in_mem_read;
assign out_branch_inst = in_branch_inst;
assign out_mem_to_reg = in_mem_to_reg;
assign out_write_enable = in_write_enable;

alu alu(
    .opcode(in_opcode),
    .funct3(in_funct3),
    .funct7(in_funct7),
    .operand1(in_rs1),
    .operand2(in_rs2),
    .immediate(in_immediate), //This renders alu_src useless
    .PC(in_PC),
    .alu_out(out_alu_out),
    .out_PC(out_PC),
    .branch_taken(out_branch_taken),
);
    

endmodule
