`include "defines.sv"
`include "stage1_fetch.sv"
`include "registers_IFID.sv"
`include "stage2_decode.sv"
`include "registers_IDEX.sv"
`include "stage3_execute.sv"
`include "registers_EXMEM.sv"
`include "stage4_memory.sv"
`include "registers_MEMWB.sv"
`include "stage5_writeback.sv"

module core (
    input clk,
    input reset,
    output reg [31:0] r1_out
);

//FETCH STAGE
wire [31:0] fetch_to_registers_pc;
wire [31:0] fetch_to_registers_inst;


wire EXMEM_to_fetch_branch_taken;
wire [31:0] EXMEM_to_fetch_PC;

stage_fetch fetch(
    .clk(clk),    
    .reset(reset),
    .branch_taken(EXMEM_to_fetch_branch_taken),
    .new_pc(EXMEM_to_fetch_PC),
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
wire decode_to_registers_MEM_branch_inst;
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

wire [31:0] tmp_r1;

//wires for 
//Writeback Stage --> Decode Stage
wire [31:0] writeback_to_decode_out_data;
wire [4:0] writeback_to_decode_rd;
wire writeback_to_decode_write_enable;

stage_decode decode(
    .clk(clk),
    .reset(reset),

    .in_instruction(instruction),
    .in_PC(PC),

    //INPUT FROM WB
    //This should come from control from WB
    .in_write_enable(writeback_to_decode_write_enable),
    //This should come from control from WB
    .in_write_reg(writeback_to_decode_rd),
    //This should come from WB
    .in_write_data(writeback_to_decode_out_data),

    //OUTPUT
        //CONTROL
    .EX_alu_src(decode_to_registers_EX_alu_src),
    .EX_alu_op(decode_to_registers_EX_alu_op),

    .MEM_mem_write(decode_to_registers_MEM_mem_write),
    .MEM_mem_read(decode_to_registers_MEM_mem_read),
    .MEM_branch_inst(decode_to_registers_MEM_branch_inst),

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

    .r1(tmp_r1)
);

//wires for
//IDEX Registers --> Execute Stage

wire [31:0] IDEX_to_execute_instr;
wire [31:0] IDEX_to_execute_PC;
wire [31:0] IDEX_to_execute_immediate;

wire [31:0] IDEX_to_execute_rs1;
wire [31:0] IDEX_to_execute_rs2;
wire [4:0]  IDEX_to_execute_rd;

//CONTROL
wire IDEX_to_execute_alu_src;
wire [31:0] IDEX_to_execute_inst;
wire [2:0] IDEX_to_execute_alu_op;
wire IDEX_to_execute_mem_write;
wire IDEX_to_execute_mem_read;
wire IDEX_to_execute_branch_inst;
wire IDEX_to_execute_mem_to_reg;
wire IDEX_to_execute_write_enable;

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

    .in_alu_src(decode_to_registers_EX_alu_src),
    .in_alu_op(decode_to_registers_EX_alu_op),
    
    .in_funct7(decode_to_registers_funct7),
    .in_funct3(decode_to_registers_funct3),
    .in_opcode(decode_to_registers_opcode),
    .in_instr_type(decode_to_registers_instr_type),

    //Passing by
    .in_rd(decode_to_registers_rd),
        //Control
    .in_mem_write(decode_to_registers_MEM_mem_write),
    .in_mem_read(decode_to_registers_MEM_mem_read),
    .in_branch_inst(decode_to_registers_MEM_branch_inst),
    .in_mem_to_reg(decode_to_registers_WB_write_mem_to_reg),
    .in_write_enable(decode_to_registers_WB_write_enable),

    
    //OUTPUT
    .out_instruction(IDEX_to_execute_inst),
    .out_PC(IDEX_to_execute_PC),

    .out_immediate(IDEX_to_execute_immediate),
    .out_rs1(IDEX_to_execute_rs1),
    .out_rs2(IDEX_to_execute_rs2),
    .out_rd(IDEX_to_execute_rd),

    .out_alu_src(IDEX_to_execute_alu_src),
    .out_alu_op(IDEX_to_execute_alu_op),
    .out_mem_write(IDEX_to_execute_mem_write),
    .out_mem_read(IDEX_to_execute_mem_read),
    .out_branch_inst(IDEX_to_execute_branch_inst),
    .out_mem_to_reg(IDEX_to_execute_mem_to_reg),
    .out_write_enable(IDEX_to_execute_write_enable),

    .out_funct7(IDEX_to_execute_funct7),
    .out_funct3(IDEX_to_execute_funct3),
    .out_opcode(IDEX_to_execute_opcode),
    .out_instr_type(IDEX_to_execute_instr_type)
);

//wires for
//Execute Stage --> Registers EXMEM
wire [31:0] execute_to_registers_alu_out;
wire [31:0] execute_to_registers_PC;
wire execute_to_registers_branch_taken;

wire [4:0] execute_to_registers_rd;
wire [31:0] execute_to_registers_mem_data;
wire execute_to_registers_mem_write;
wire execute_to_registers_mem_read;
wire execute_to_registers_branch_inst;
wire execute_to_registers_mem_to_reg;
wire execute_to_registers_write_enable;

stage_execute execute(
    //INPUT
    .clk(clk),
    .reset(reset),

    .in_instruction(IDEX_to_execute_inst),
    .in_PC(IDEX_to_execute_PC),

    .in_rs1(IDEX_to_execute_rs1),
    .in_rs2(IDEX_to_execute_rs2),
    .in_immediate(IDEX_to_execute_immediate),

    //CONTROL
    .in_alu_src(IDEX_to_execute_alu_src),
    .in_alu_op(IDEX_to_execute_alu_op),
    //Passing by
    .in_rd(IDEX_to_execute_rd),
        //Control
    .in_mem_write(IDEX_to_execute_mem_write),
    .in_mem_read(IDEX_to_execute_mem_read),
    .in_branch_inst(IDEX_to_execute_branch_inst),
    .in_mem_to_reg(IDEX_to_execute_mem_to_reg),
    .in_write_enable(IDEX_to_execute_write_enable),

    .in_funct7(IDEX_to_execute_funct7),
    .in_funct3(IDEX_to_execute_funct3),
    .in_opcode(IDEX_to_execute_opcode),
    .in_instr_type(IDEX_to_execute_instr_type),


    //OUTPUT
    .out_alu_out(execute_to_registers_alu_out),
    .out_mem_data(execute_to_registers_mem_data),
    .out_PC(execute_to_registers_PC),
    .out_branch_taken(execute_to_registers_branch_taken),

    .out_rd(execute_to_registers_rd),
    .out_mem_write(execute_to_registers_mem_write),
    .out_mem_read(execute_to_registers_mem_read),
    .out_branch_inst(execute_to_registers_branch_inst),
    .out_mem_to_reg(execute_to_registers_mem_to_reg),
    .out_write_enable(execute_to_registers_write_enable)
);

//wires for
//EXMEM Registers --> Memory Stage
//To Fetch Stage
wire EXMEM_to_memory_branch_inst;

//Actual memory interaction
wire [31:0] EXMEM_to_memory_alu_out;
wire [31:0] EXMEM_to_memory_mem_data;

//Control
wire EXMEM_to_memory_mem_write;
wire EXMEM_to_memory_mem_read;

//Passing by
wire [4:0] EXMEM_to_memory_rd;
wire EXMEM_to_memory_mem_to_reg;
wire EXMEM_to_memory_write_enable;

registers_EXMEM registers_EXMEM(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_alu_out(execute_to_registers_alu_out),
    .in_new_PC(execute_to_registers_PC),
    .in_branch_taken(execute_to_registers_branch_taken),

    //Passing by
    .in_rd(execute_to_registers_rd),
        //Control
    .in_mem_data(execute_to_registers_mem_data),
    .in_mem_write(execute_to_registers_mem_write),
    .in_mem_read(execute_to_registers_mem_read),
    .in_branch_inst(execute_to_registers_branch_inst),
    .in_mem_to_reg(execute_to_registers_mem_to_reg),
    .in_write_enable(execute_to_registers_write_enable),

    //OUTPUT
    //To Fetch Stage
    .out_new_PC(EXMEM_to_fetch_PC),
    .out_branch_taken(EXMEM_to_fetch_branch_taken),
    .out_branch_inst(EXMEM_to_memory_branch_inst),

    //Actual memory interaction
    .out_alu_out(EXMEM_to_memory_alu_out),
    .out_mem_data(EXMEM_to_memory_mem_data),

    //Control
    .out_mem_write(EXMEM_to_memory_mem_write),
    .out_mem_read(EXMEM_to_memory_mem_read),

    //Passing by    
    .out_rd(EXMEM_to_memory_rd),
    .out_mem_to_reg(EXMEM_to_memory_mem_to_reg),
    .out_write_enable(EXMEM_to_memory_write_enable)
);

//wires for
//Memory Stage --> MEMWB Registers
wire [31:0] memory_to_MEMWB_alu_out;
wire [31:0] memory_to_MEMWB_mem_out;
wire memory_to_MEMWB_rd;
wire memory_to_MEMWB_mem_to_reg;
wire memory_to_MEMWB_write_enable;
 
stage_memory dmemory(
    .clk(clk),
    .reset(reset),

    //INPUT
    //Actual memory interaction
    .in_alu_out(EXMEM_to_memory_alu_out),
    .in_mem_data(EXMEM_to_memory_mem_data),

    //Control
    .in_mem_write(EXMEM_to_memory_mem_write),
    .in_mem_data(EXMEM_to_memory_mem_data),

    //Passing by
    .in_rd(EXMEM_to_memory_rd),
    .in_mem_to_reg(EXMEM_to_memory_mem_to_reg),
    .in_write_enable(EXMEM_to_memory_write_enable),

    //OUTPUT
    .out_alu_out(memory_to_MEMWB_alu_out),
    .out_mem_out(memory_to_MEMWB_mem_out),
    .out_rd(memory_to_MEMWB_rd),
    .out_mem_to_reg(memory_to_MEMWB_mem_to_reg),
    .out_write_enable(memory_to_MEMWB_write_enable)
);

//wires for
//MEMWB Registers --> Writeback Stage
wire [31:0] MEMWB_to_writeback_alu_out;
wire [31:0] MEMWB_to_writeback_mem_out;

wire [4:0] MEMWB_to_writeback_rd;
wire MEMWB_to_writeback_mem_to_reg;
wire MEMWB_to_writeback_write_enable;

registers_MEMWB registers_MEMWB(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_alu_out(memory_to_MEMWB_alu_out),
    .in_mem_out(memory_to_MEMWB_mem_out),

    .in_rd(memory_to_MEMWB_rd),
    .in_mem_to_reg(memory_to_MEMWB_mem_to_reg),
    .in_write_enable(memory_to_MEMWB_write_enable),

    //OUTPUT
    .out_alu_out(MEMWB_to_writeback_alu_out),
    .out_mem_out(MEMWB_to_writeback_mem_out),

    .out_rd(MEMWB_to_writeback_rd),
    .out_mem_to_reg(MEMWB_to_writeback_mem_to_reg),
    .out_write_enable(MEMWB_to_writeback_write_enable)
);

stage_writeback writeback(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_alu_out(MEMWB_to_writeback_alu_out),
    .in_mem_out(MEMWB_to_writeback_mem_out),

    .in_rd(MEMWB_to_writeback_rd),
    .in_mem_to_reg(MEMWB_to_writeback_mem_to_reg),
    .in_write_enable(MEMWB_to_writeback_write_enable),

    //OUTPUT
    .out_data(writeback_to_decode_out_data),
    .out_rd(writeback_to_decode_rd),
    .out_write_enable(writeback_to_decode_write_enable)
);

always @(posedge clk) r1_out <= tmp_r1;
endmodule
