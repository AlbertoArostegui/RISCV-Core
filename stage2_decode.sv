`include "register_file.sv"
`include "decoder.sv"
`include "control.sv"

module stage_decode(
    input clk,
    input reset,

    //Passing on
    input [31:0] in_instruction,
    input [31:0] in_PC,

    //To modify Register File
    //This comes from WB
    input in_write_enable,
    input [4:0] in_write_reg,
    input [31:0] in_write_data,

    //CONTROL    
    //For EX
    output EX_alu_src,
    output [2:0] EX_alu_op,
    
    //For MEM
    output MEM_mem_write,
    output MEM_mem_read,
    output MEM_branch_inst,

    //For WB
    output WB_write_mem_to_reg,
    output WB_write_enable,


    //Output from RF, data
    output [4:0] out_rs1,
    output [4:0] out_rs2,

    output [31:0] out_data_a,
    output [31:0] out_data_b,

    output [31:0] out_PC,
    output [31:0] out_instruction,
    output [31:0] out_immediate,
    output [4:0] out_rd,

    //Output from decoder for alu
    output [6:0] out_funct7,
    output [2:0] out_funct3,
    output [6:0] out_opcode,
    output [2:0] out_instr_type
);

wire [4:0] decoder_to_rf_rs1;
wire [4:0] decoder_to_rf_rs2;

assign out_instruction = in_instruction;
assign out_PC = in_PC;

decoder decoder(
    .instr(in_instruction),     //In
    .rs1(decoder_to_rf_rs1),    //Out
    .rs2(decoder_to_rf_rs2),
    .rd(out_rd),
    .imm(out_immediate),
    .funct7(out_funct7),
    .funct3(out_funct3),
    .opcode(out_opcode),
    .instr_type(out_instr_type)
);

assign out_rs1 = decoder_to_rf_rs1;
assign out_rs2 = decoder_to_rf_rs2;

register_file RF(
    .clk(clk),                  //In 
    .reset(reset),
    .we(in_write_enable),
    .wreg(in_write_reg),
    .wdata(in_write_data),      
    .reg_a(decoder_to_rf_rs1), 
    .reg_b(decoder_to_rf_rs2),  
    .out_data_a(out_data_a),    //Out
    .out_data_b(out_data_b)    
);

control control(
    .in_instruction(in_instruction),            //In
    .EX_alu_src(EX_alu_src),                    //Out
    .EX_alu_op(EX_alu_op),
    .MEM_mem_write(MEM_mem_write),
    .MEM_mem_read(MEM_mem_read),
    .MEM_branch_inst(MEM_branch_inst),
    .WB_write_mem_to_reg(WB_write_mem_to_reg),
    .WB_write_enable(WB_write_enable)
);

endmodule
