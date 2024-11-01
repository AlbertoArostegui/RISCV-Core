`include "register_file.sv"
`include "decoder.sv"

module stage_decode(
    input clk,
    input reset,

    //Passing on
    input [31:0] in_instruction,
    input [31:0] in_PC,

    //To modify Register File
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

    //For WB
    output WB_write_mem_to_reg,
    output WB_write_enable,


    //Output from RF, data
    output [31:0] out_data_a,
    output [31:0] out_data_b,

    output [31:0] out_immediate,
    output [4:0] out_rd

);

wire [4:0] decoder_to_rf_rs1;
wire [4:0] decoder_to_rf_rs2;

decoder decoder(
    .instruction(instruction),
    .rs1(decoder_to_rf_rs1),
    .rs2(decoder_to_rf_rs2),
    .rd(out_rd),
    .imm(out_immediate),
    .funct7(),
    .funct3(),
    .opcode(),
    .instr_type()
);

register_file RF(
    .clk(clk), 
    .reset(reset),
    .we(in_write_enable),
    .wreg(in_write_reg),
    .wdata(in_write_data),
    .reg_a(decoder_to_rf_rs1),
    .reg_b(decoder_to_rf_rs1),
    .out_data_a(out_data_a),
    .out_data_b(out_data_b)
);

endmodule
