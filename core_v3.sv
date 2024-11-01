`include "defines.sv"
`include "stage1_fetch.sv"
`include "registers_IFID.sv"
`include "stage2_decode.sv"

module core (
    input clk,
    input reset
)

//FETCH STAGE
wire [31:0] fetch_to_registers_pc;
wire [31:0] fetch_to_registers_inst;

stage_fetch fetch(
    .clk(clk),    
    .reset(reset),
    .branch_taken(),
    .new_pc(),
    .out_pc(fetch_to_registers_pc),
    .inst_out(fetch_to_registers_inst)
);

wire [31:0] registers_IFID_to_decode_instruction;
wire [31:0] registers_IFID_to_decode_PC;

registers_IFID registers_IFID(
    .clk(clk),
    .reset(reset),

    .in_instruction(fetch_to_registers_inst),
    .in_PC(fetch_to_registers_pc),

    .out_instruction(registers_IFID_to_decode_instruction),
    .out_PC(registers_IFID_to_decode_PC)
);

//CONTROL
//EX
wire decode_to_registers_EX_alu_src;
wire [2:0] decode_to_registers_EX_alu_op;
//MEM
wire decode_to_registers_MEM_mem_write;
wire decode_to_registers_MEM_mem_read;
//WB
wire decode_to_registers_WB_write_mem_to_reg;
wire decode_to_registers_WB_write_enable;

//Data from registers to be passed to next pipeline stage
wire [31:0] decode_to_registers_data_a;
wire [31:0] decode_to_registers_data_b;

stage_decode decode(
    .clk(clk),
    .reset(reset),

    .instruction(registers_IFID_to_decode_instruction),
    .in_PC(registers_IFID_to_decode_PC),

    //This should come from control from WB
    .in_write_enable(),
    //This should come from control from WB
    .in_write_reg(),
    //This should come from WB
    .in_write_data(),

    .out_data_a(decode_to_registers_data_a),
    .out_data_b(decode_to_registers_data_b),

    .EX_alu_src(decode_to_registers_EX_alu_src),
    .EX_alu_op(decode_to_registers_EX_alu_op),

    .MEM_mem_write(decode_to_registers_MEM_mem_write),
    .MEM_mem_read(decode_to_registers_MEM_mem_read),

    .WB_write_mem_to_reg(decode_to_registers_WB_write_mem_to_reg),
    .WB_write_enable(decode_to_registers_WB_write_enable)
);
