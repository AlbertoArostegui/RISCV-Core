`include "alu.sv"
`include "forwarding_unit.sv"

module stage_execute(
    input clk,
    input reset,

    //INPUT
    input [31:0] in_instruction,
    input [31:0] in_PC,

    //Alu
    input [31:0] in_data_rs1,
    input [31:0] in_data_rs2,
    input [31:0] in_immediate,

    //Alu control
    input in_alu_src,
    input [2:0] in_alu_op,

    //Forwarding Unit
    input [4:0] in_rs1,
    input [4:0] in_rs2,
    input [4:0] in_EXMEM_rd,
    input [4:0] in_MEMWB_rd,
    input in_EXMEM_write_enable,
    input in_MEMWB_write_enable,
    input [31:0] in_EXMEM_alu_out,
    input [31:0] in_MEMWB_out_data,

    input [6:0] in_funct7,
    input [2:0] in_funct3,
    input [6:0] in_opcode,
    input [2:0] in_instr_type,

    //Passing by
    input [4:0] in_IDEX_rd,

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
    output out_flush,

    output [4:0] out_rd,
    output [31:0] out_mem_in_data,
    output out_mem_write,
    output out_mem_read,
    output out_branch_inst,
    output out_mem_to_reg,
    output out_write_enable
);

assign out_rd = in_IDEX_rd;
assign out_mem_write = in_mem_write;
assign out_mem_read = in_mem_read;
assign out_branch_inst = in_branch_inst;
assign out_mem_to_reg = in_mem_to_reg;
assign out_write_enable = in_write_enable;

forwarding_unit forwarding_unit(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_IDEX_rs1(in_rs1),
    .in_IDEX_rs2(in_rs2),
    .in_EXMEM_rd(in_EXMEM_rd),
    .in_MEMWB_rd(in_MEMWB_rd),
    .in_EXMEM_write_enable(in_EXMEM_write_enable),
    .in_MEMWB_write_enable(in_MEMWB_write_enable),

    //OUTPUT
    .forwardA(forwardA),
    .forwardB(forwardB)
);

wire [1:0] forwardA;
wire [1:0] forwardB;
wire [31:0] alu_operand1;
wire [31:0] alu_operand2;

// MUX for forwarding
assign alu_operand1 = (forwardA == 2'b10) ? in_EXMEM_alu_out :
                     (forwardA == 2'b01) ? in_MEMWB_out_data :
                     in_data_rs1;

assign alu_operand2 = (forwardB == 2'b10) ? in_EXMEM_alu_out :
                     (forwardB == 2'b01) ? in_MEMWB_out_data :
                     in_data_rs2;
                     
//IMPORTANT: This is the data that will be stored in the memory. It also comes
//from the registers so hazards could happen. It must be after the first MUX
//(see Patterson Hennessy)
assign out_mem_in_data = alu_operand2;

alu alu(
    //INPUT
    .opcode(in_opcode),
    .funct3(in_funct3),
    .funct7(in_funct7),
    .operand1(alu_operand1),
    .operand2(alu_operand2),
    .immediate(in_immediate),
    .PC(in_PC),

    //OUTPUT
    .alu_out(out_alu_out),
    .out_PC(out_PC),
    .branch_taken(out_branch_taken)
);
    
assign out_flush = out_branch_taken;

endmodule
