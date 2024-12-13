`include "register_file.sv"
`include "decoder.sv"
`include "control.sv"
`include "hazard_detection_unit.sv"

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

    input [4:0] in_IDEX_rd,
    input in_IDEX_mem_read,

    //Exception
    input [2:0] in_exception_vector,

    //OUTPUT
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

    //Forwarding
    output [4:0] out_rs1,
    output [4:0] out_rs2,

    //Output from RF, data
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
    output [2:0] out_instr_type,

    output out_pc_write_disable,
    output out_IFID_write_disable,

    //Exception
    output [2:0] out_exception_vector
);

wire [4:0] decoder_to_rf_rs1;
wire [4:0] decoder_to_rf_rs2;

assign out_instruction = in_instruction;
assign out_PC = in_PC;
assign out_exception_vector = in_exception_vector;

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

wire stall_pipeline;
wire control_src;

wire EX_alu_src_pre;
wire [2:0] EX_alu_op_pre;
wire MEM_mem_write_pre;
wire MEM_mem_read_pre;
wire MEM_branch_inst_pre;
wire WB_write_mem_to_reg_pre;
wire WB_write_enable_pre;

hazard_detection_unit hazard_detection_unit(
    .in_IDEX_mem_read(in_IDEX_mem_read),       //In
    .in_IDEX_rd(in_IDEX_rd),
    .in_IFID_rs1(decoder_to_rf_rs1),
    .in_IFID_rs2(decoder_to_rf_rs2),

    .out_stall(stall_pipeline),                             //Out
    .out_pc_write_disable(out_pc_write_disable),         
    .out_IFID_write_disable(out_IFID_write_disable),     
    .out_control_src(control_src)
);

control control(
    .in_instruction(in_instruction),            //In

    .EX_alu_src(EX_alu_src_pre),                //Out
    .EX_alu_op(EX_alu_op_pre),
    .MEM_mem_write(MEM_mem_write_pre),
    .MEM_mem_read(MEM_mem_read_pre),
    .MEM_branch_inst(MEM_branch_inst_pre),
    .WB_write_mem_to_reg(WB_write_mem_to_reg_pre),
    .WB_write_enable(WB_write_enable_pre)
);

//If control_src is 0, stall the pipeline
assign EX_alu_src = control_src ? EX_alu_src_pre : 1'b0;
assign EX_alu_op = control_src ? EX_alu_op_pre : 3'b0;
assign MEM_mem_write = control_src ? MEM_mem_write_pre : 1'b0;
assign MEM_mem_read = control_src ? MEM_mem_read_pre : 1'b0;
assign MEM_branch_inst = control_src ? MEM_branch_inst_pre : 1'b0;
assign WB_write_mem_to_reg = control_src ? WB_write_mem_to_reg_pre : 1'b0;
assign WB_write_enable = control_src ? WB_write_enable_pre : 1'b0;

endmodule
