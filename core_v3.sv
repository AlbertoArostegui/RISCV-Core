`include "defines.sv"
`include "stage1_fetch.sv"
`include "registers_IFID.sv"
`include "stage2_decode.sv"
`include "registers_IDEX"

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

//wires for
//Registers IFID --> Decode Stage

wire [31:0] instruction;
wire [31:0] PC;

registers_IFID registers_IFID(
    .clk(clk),
    .reset(reset),

    .in_instruction(fetch_to_registers_inst),
    .in_PC(fetch_to_registers_pc),

    .out_instruction(instruction),
    .out_PC(PC)
);

//wires for
//Decode Stage --> Registers IDEX

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
wire [31:0] decode_to_registers_data_a; //(rs1)
wire [31:0] decode_to_registers_data_b; //(rs2)

wire [6:0] decode_to_registers_funct7;
wire [2:0] decode_to_registers_funct3;
wire [5:0] decode_to_registers_opcode;
wire [2:0] decode_to_registers_instr_type;

wire [31:0] decode_to_registers_immediate;
wire [4:0] decode_to_registers_rd;

stage_decode decode(
    .clk(clk),
    .reset(reset),

    .in_instruction(instruction),
    .in_PC(PC),

    //INPUT FROM WB
    //This should come from control from WB
    .in_write_enable(),
    //This should come from control from WB
    .in_write_reg(),
    //This should come from WB
    .in_write_data(),

    //OUTPUT
        //CONTROL
    .EX_alu_src(decode_to_registers_EX_alu_src),
    .EX_alu_op(decode_to_registers_EX_alu_op),

    .MEM_mem_write(decode_to_registers_MEM_mem_write),
    .MEM_mem_read(decode_to_registers_MEM_mem_read),

    .WB_write_mem_to_reg(decode_to_registers_WB_write_mem_to_reg),
    .WB_write_enable(decode_to_registers_WB_write_enable),
    
    .out_data_a(decode_to_registers_data_a),
    .out_data_b(decode_to_registers_data_b),

    .out_immediate(decode_to_registers_immediate),
    .out_rd(decode_to_registers_rd),

        //OUTPUT FROM DECODER
    .out_funct7(decode_to_registers_funct7),
    .out_funct3(decode_to_registers_funct3),
    .out_opcode(decode_to_registers_opcode),
    .out_instr_type(decode_to_registers_instr_type),
);

//wires for
//IDEX Registers --> Execute Stage

wire [31:0] IDEX_to_execute_instr;
wire [31:0] IDEX_to_execute_PC;
wire [31:0] IDEX_to_execute_immediate;

wire [31:0] IDEX_to_execute_rs1;
wire [31:0] IDEX_to_execute_rs2;
wire [4:0]  IDEX_to_execute_rd;

wire IDEX_to_execute_alu_src;
wire [2:0] IDEX_to_execute_alu_op;

wire [6:0] IDEX_to_execute_funct7;
wire [2:0] IDEX_to_execute_funct3;
wire [5:0] IDEX_to_execute_opcode;
wire [2:0] IDEX_to_execute_instr_type;

registers_IDEX registers_IDEX(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_instruction(instruction),
    .in_PC(PC),

    .in_immediate(decode_to_registers_immediate),
    .in_rs1(decode_to_registers_data_a),
    .in_rs2(decode_to_registers_data_b),
    .in_rd(decode_to_registers_rd),

    .in_alu_src(decode_to_registers_EX_alu_src),
    .in_alu_op(decode_to_registers_EX_alu_op),
    
    .in_funct7(decode_to_registers_funct7),
    .in_funct3(decode_to_registers_funct3),
    .in_opcode(decode_to_registers_opcode),
    .in_instr_type(decode_to_registers_instr_type),

    //OUTPUT
    .out_instruction(IDEX_to_execute_instruction),
    .out_PC(IDEX_to_execute_PC),

    .out_immediate(IDEX_to_execute_immediate),
    .out_rs1(IDEX_to_execute_rs1),
    .out_rs2(IDEX_to_execute_rs2),
    .out_rd(IDEX_to_execute_rd),

    .out_alu_src(IDEX_to_execute_alu_src),
    .out_alu_op(IDEX_to_execute_alu_op),

    .out_funct7(IDEX_to_execute_funct7),
    .out_funct3(IDEX_to_execute_funct3),
    .out_opcode(IDEX_to_execute_opcode),
    .out_instr_type(IDEX_to_execute_instr_type)
);
