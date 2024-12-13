`include "defines.sv"
`include "stage1_fetch.sv"
`include "registers1_IFID.sv"
`include "stage2_decode.sv"
`include "registers2_IDEX.sv"
`include "stage3_execute.sv"
`include "registers3_EXMEM.sv"
`include "stage4_memory.sv"
`include "stage4_cache.sv"
`include "registers4_MEMWB.sv"
`include "stage5_writeback.sv"
`include "reorder_buffer.sv"

module core #(
    parameter int CACHE_LINE_SIZE = 128
) (
    input clk,
    input reset,

    //INPUT
        //iCache
    input [CACHE_LINE_SIZE-1:0] in_imem_read_data,
    input in_imem_ready,
        //dCache
    input [CACHE_LINE_SIZE-1:0] in_dmem_read_data,
    input in_dmem_ready,

    //OUTPUT
        //iCache
    output out_imem_read_en,
    output out_imem_write_en,
    output [31:0] out_imem_addr,
    output [CACHE_LINE_SIZE-1:0] out_imem_write_data,
        //dCache
    output out_dmem_read_en,
    output out_dmem_write_en,
    output [31:0] out_dmem_addr,
    output [CACHE_LINE_SIZE-1:0] out_dmem_write_data
);

//FETCH STAGE
wire [31:0] fetch_to_registers_pc;
wire [31:0] fetch_to_registers_inst;

//FROM Decode Stage
wire pc_write_disable;

//FROM Execute Stage
wire execute_to_fetch_branch_taken;
wire [31:0] execute_to_fetch_PC;
wire flush;

//Stalls
wire i_cache_stall;
wire d_cache_stall;

//Exception vector
wire [2:0] fetch_to_registers_exception_vector;

stage_fetch fetch(
    .clk(clk),    
    .reset(reset),

    //INPUT
    .branch_taken(execute_to_fetch_branch_taken),
    .new_pc(execute_to_fetch_PC),
    .pc_write_disable(pc_write_disable),

    //MEM IFACE
    .in_mem_read_data(in_imem_read_data),
    .in_mem_ready(in_imem_ready),

    //OUTPUT
    .out_PC(fetch_to_registers_pc),
    .out_instruction(fetch_to_registers_inst),
    .out_stall(i_cache_stall),

    //MEM IFACE
    .out_mem_read_en(out_imem_read_en),
    .out_mem_write_en(out_imem_write_en),
    .out_mem_addr(out_imem_addr),
    .out_mem_write_data(out_imem_write_data),

    //Exception
    .out_exception_vector(fetch_to_registers_exception_vector)
);

//wires for
//Registers IFID --> Decode Stage

wire [31:0] IFID_to_decode_instruction;
wire [31:0] IFID_to_decode_PC;

//FROM Decode Stage
wire IFID_write_disable;

//FROM ROB
wire [3:0] rob_to_registers_IFID_idx;

//ROB
wire [3:0] IFID_to_decode_complete_idx;

//Exception vector
wire [2:0] IFID_to_decode_exception_vector;

registers_IFID registers_IFID(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_instruction(fetch_to_registers_inst),
    .in_PC(fetch_to_registers_pc),

    //CONTROL
    .in_IFID_write_disable(IFID_write_disable),
    .in_IFID_flush(flush),

    //Control - Stall
    .in_i_cache_stall(i_cache_stall),
    .in_d_cache_stall(d_cache_stall),

    //ROB
    .in_complete_idx(rob_to_registers_IFID_idx),

    //Exception vector
    .in_exception_vector(fetch_to_registers_exception_vector),

    //OUTPUT
    .out_instruction(IFID_to_decode_instruction),
    .out_PC(IFID_to_decode_PC),

    //ROB
    .out_complete_idx(IFID_to_decode_complete_idx),

    //Exception vector
    .out_exception_vector(IFID_to_decode_exception_vector)
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
wire [6:0] decode_to_registers_opcode;
wire [2:0] decode_to_registers_instr_type;

wire [31:0] decode_to_registers_and_ROB_PC;
wire [31:0] decode_to_registers_instruction;
wire [31:0] decode_to_registers_immediate;
wire [4:0] decode_to_registers_rs1;
wire [4:0] decode_to_registers_rs2;
wire [4:0] decode_to_registers_and_ROB_rd;


//wires for 
//Writeback Stage --> Decode Stage
wire [31:0] writeback_to_decode_and_execute_out_data;
wire [4:0] writeback_to_decode_rd;
wire writeback_to_decode_write_enable;

//FROM IDEX
wire [4:0] IDEX_to_decode_and_execute_rd;
wire IDEX_to_decode_and_execute_mem_read;

//ROB
wire [3:0] decode_to_registers_complete_idx;

//Exception vector
wire [2:0] decode_to_registers_exception_vector;

stage_decode decode(
    .clk(clk),
    .reset(reset),

    .in_instruction(IFID_to_decode_instruction),
    .in_PC(IFID_to_decode_PC),

    //INPUT FROM WB
    //This should come from control from WB
    .in_write_enable(writeback_to_decode_write_enable),
    //This should come from control from WB
    .in_write_reg(writeback_to_decode_rd),
    //This should come from WB
    .in_write_data(writeback_to_decode_and_execute_out_data),

    //Hazard Detection Unit
    .in_IDEX_rd(IDEX_to_decode_and_execute_rd),
    .in_IDEX_mem_read(IDEX_to_decode_and_execute_mem_read),

    //ROB
    .in_complete_idx(IFID_to_decode_complete_idx),

    //Exception vector
    .in_exception_vector(IFID_to_decode_exception_vector),

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

    .out_PC(decode_to_registers_and_ROB_PC),
    .out_instruction(decode_to_registers_instruction),
    .out_immediate(decode_to_registers_immediate),
    .out_rs1(decode_to_registers_rs1),
    .out_rs2(decode_to_registers_rs2),
    .out_rd(decode_to_registers_and_ROB_rd),

        //OUTPUT FROM DECODER
    .out_funct7(decode_to_registers_funct7),
    .out_funct3(decode_to_registers_funct3),
    .out_opcode(decode_to_registers_opcode),
    .out_instr_type(decode_to_registers_instr_type),

    .out_pc_write_disable(pc_write_disable),
    .out_IFID_write_disable(IFID_write_disable)

    //ROB
    .out_complete_idx(decode_to_registers_complete_idx),

    //Exception vector
    .out_exception_vector(decode_to_registers_exception_vector)
);

//wires for
//IDEX Registers --> Execute Stage

wire [31:0] IDEX_to_execute_instr;
wire [31:0] IDEX_to_execute_PC;
wire [31:0] IDEX_to_execute_immediate;

wire [4:0] IDEX_to_execute_rs1;
wire [4:0] IDEX_to_execute_rs2;
wire [4:0]  IDEX_to_execute_rd;

wire [31:0] IDEX_to_execute_data_rs1;
wire [31:0] IDEX_to_execute_data_rs2;

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
wire [6:0] IDEX_to_execute_opcode;
wire [2:0] IDEX_to_execute_instr_type;

//ROB
wire [3:0] IDEX_to_execute_complete_idx;

//Exception vector
wire [2:0] IDEX_to_execute_exception_vector;

registers_IDEX registers_IDEX(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_instruction(decode_to_registers_instruction),
    .in_PC(decode_to_registers_PC),

    .in_immediate(decode_to_registers_immediate),
    .in_data_rs1(decode_to_registers_data_a),
    .in_data_rs2(decode_to_registers_data_b),
    .in_rs1(decode_to_registers_rs1),
    .in_rs2(decode_to_registers_rs2),

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

    //CONTROL
    .in_IDEX_flush(flush),

    //Control - Stall
    .in_d_cache_stall(d_cache_stall),

    //ROB
    .in_complete_idx(),

    //Exception vector
    .in_exception_vector(decode_to_registers_exception_vector),
    
    //OUTPUT
    .out_instruction(IDEX_to_execute_inst),
    .out_PC(IDEX_to_execute_PC),

    .out_immediate(IDEX_to_execute_immediate),
    .out_data_rs1(IDEX_to_execute_data_rs1),
    .out_data_rs2(IDEX_to_execute_data_rs2),
    .out_rs1(IDEX_to_execute_rs1),
    .out_rs2(IDEX_to_execute_rs2),
    .out_rd(IDEX_to_decode_and_execute_rd),

    .out_alu_src(IDEX_to_execute_alu_src),
    .out_alu_op(IDEX_to_execute_alu_op),
    .out_mem_write(IDEX_to_decode_and_execute_mem_write),
    .out_mem_read(IDEX_to_decode_and_execute_mem_read),
    .out_branch_inst(IDEX_to_execute_branch_inst),
    .out_mem_to_reg(IDEX_to_execute_mem_to_reg),
    .out_write_enable(IDEX_to_execute_write_enable),

    .out_funct7(IDEX_to_execute_funct7),
    .out_funct3(IDEX_to_execute_funct3),
    .out_opcode(IDEX_to_execute_opcode),
    .out_instr_type(IDEX_to_execute_instr_type),

    //ROB
    .out_complete_idx(IDEX_to_execute_complete_idx),

    //Exception vector
    .out_exception_vector(IDEX_to_execute_exception_vector)
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
wire [2:0] execute_to_registers_funct3;

//Forwarding Unit: EXMEM --> Execute, Cache, WB
wire EXMEM_to_execute_and_writeback_write_enable;
wire [4:0] MEMWB_to_execute_and_writeback_rd;

wire EXMEM_to_execute_and_cache_write_enable;
wire [4:0] EXMEM_to_execute_and_cache_rd;
wire [31:0] EXMEM_to_execute_and_cache_alu_out; //For EX data hazards

//ROB
wire [3:0] execute_to_registers_complete_idx;

//Exception vector
wire [2:0] execute_to_registers_exception_vector;

stage_execute execute(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_instruction(IDEX_to_execute_inst),
    .in_PC(IDEX_to_execute_PC),

    .in_data_rs1(IDEX_to_execute_data_rs1),
    .in_data_rs2(IDEX_to_execute_data_rs2),
    .in_immediate(IDEX_to_execute_immediate),

        //CONTROL
        //Forwarding Unit
    .in_rs1(IDEX_to_execute_rs1),
    .in_rs2(IDEX_to_execute_rs2),
    .in_EXMEM_rd(EXMEM_to_execute_and_cache_rd),
    .in_MEMWB_rd(MEMWB_to_execute_and_writeback_rd),
    .in_EXMEM_write_enable(EXMEM_to_execute_and_cache_write_enable),
    .in_MEMWB_write_enable(MEMWB_to_execute_and_writeback_write_enable),
    .in_EXMEM_alu_out(EXMEM_to_execute_and_cache_alu_out),
    .in_MEMWB_out_data(writeback_to_decode_and_execute_out_data),

    .in_alu_src(IDEX_to_execute_alu_src),
    .in_alu_op(IDEX_to_execute_alu_op),
        //Passing by
    .in_IDEX_rd(IDEX_to_decode_and_execute_rd),
        //Control
    .in_mem_write(IDEX_to_decode_and_execute_mem_write),
    .in_mem_read(IDEX_to_decode_and_execute_mem_read),
    .in_branch_inst(IDEX_to_execute_branch_inst),
    .in_mem_to_reg(IDEX_to_execute_mem_to_reg),
    .in_write_enable(IDEX_to_execute_write_enable),

    .in_funct7(IDEX_to_execute_funct7),
    .in_funct3(IDEX_to_execute_funct3),
    .in_opcode(IDEX_to_execute_opcode),
    .in_instr_type(IDEX_to_execute_instr_type),

    //ROB
    .in_complete_idx(IDEX_to_execute_complete_idx),

    //Exception vector
    .in_exception_vector(IDEX_to_execute_exception_vector),

    //OUTPUT
    .out_alu_out(execute_to_registers_alu_out),
    .out_mem_in_data(execute_to_registers_mem_data),

    //Hazard Detection Unit
    .out_PC(execute_to_fetch_PC),
    .out_branch_taken(execute_to_fetch_branch_taken),
    .out_flush(flush),
    .out_funct3(execute_to_registers_funct3),

    //CONTROL

    .out_rd(execute_to_registers_rd),
    .out_mem_write(execute_to_registers_mem_write),
    .out_mem_read(execute_to_registers_mem_read),
    .out_branch_inst(execute_to_registers_branch_inst),
    .out_mem_to_reg(execute_to_registers_mem_to_reg),
    .out_write_enable(execute_to_registers_write_enable),

    //ROB
    .out_complete_idx(EXMEM_to_registers_complete_idx),

    //Exception vector
    .out_exception_vector(execute_to_registers_exception_vector)
);

//wires for
//EXMEM Registers --> Cache Stage
wire EXMEM_to_cache_branch_inst;
wire [31:0] EXMEM_to_cache_mem_data;

//Control
wire EXMEM_to_cache_mem_write;
wire EXMEM_to_cache_mem_read;
wire [2:0] EXMEM_to_cache_funct3;

//ROB
wire [31:0] EXMEM_to_rob_complete_value;
wire [4:0] EXMEM_to_rob_complete_idx;

//Passing by
wire EXMEM_to_cache_mem_to_reg;

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
    .in_funct3(execute_to_registers_funct3),

    //Control - Stall
    .in_d_cache_stall(d_cache_stall),

    //ROB
    .in_complete_idx(execute_to_registers_complete_idx),

    //Exception
    .in_exception_vector(execute_to_registers_exception_vector),

    //OUTPUT
    //To Fetch Stage
    //.out_new_PC(EXMEM_to_fetch_PC),
    //.out_branch_taken(EXMEM_to_fetch_branch_taken),
    .out_branch_inst(EXMEM_to_memory_branch_inst),

    //Actual memory interaction
    .out_alu_out(EXMEM_to_execute_and_cache_alu_out),
    .out_mem_data(EXMEM_to_cache_mem_data),

    //Control
    .out_mem_write(EXMEM_to_cache_cache_write),
    .out_mem_read(EXMEM_to_cache_cache_read),
    .out_funct3(EXMEM_to_cache_funct3),

    //Passing by    
    .out_rd(EXMEM_to_execute_and_cache_rd),
    .out_mem_to_reg(EXMEM_to_cache_mem_to_reg),
    .out_write_enable(EXMEM_to_execute_and_cache_write_enable),

    //ROB
    .out_complete_idx(EXMEM_to_rob_complete_idx),
    .out_complete_value(EXMEM_to_rob_complete_value),                   //If alu instruction, write to ROB

    //Exception
    .out_exception_vector(EXMEM_to_cache_exception_vector)
);

//wires for
//Memory Stage --> MEMWB Registers
wire [31:0] cache_to_MEMWB_alu_out;
wire [31:0] cache_to_MEMWB_cache_out;
wire [4:0] cache_to_MEMWB_rd;
wire cache_to_MEMWB_mem_to_reg;
wire cache_to_MEMWB_write_enable;

stage_cache cache(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_alu_out(EXMEM_to_execute_and_cache_alu_out),
    .in_write_data(EXMEM_to_cache_mem_data),

    //Control
    .in_write_en(EXMEM_to_cache_cache_write),
    .in_read_en(EXMEM_to_cache_cache_read),
    .in_funct3(EXMEM_to_cache_funct3),

    //Control passing by
    .in_rd(EXMEM_to_execute_and_cache_rd),
    .in_mem_to_reg(EXMEM_to_cache_mem_to_reg),
    .in_write_enable(EXMEM_to_execute_and_cache_write_enable), //Regs write enable/

    //MEM IFACE
    .in_mem_read_data(in_dmem_read_data),
    .in_mem_ready(in_dmem_ready),


    //OUTPUT
    .out_alu_out(cache_to_MEMWB_alu_out),
    .out_read_data(cache_to_MEMWB_cache_out),

    //Control - Stall
    .out_stall(d_cache_stall),

    //Control passing by
    .out_rd(cache_to_MEMWB_rd),
    .out_mem_to_reg(cache_to_MEMWB_mem_to_reg),
    .out_write_enable(cache_to_MEMWB_write_enable),

    //MEM IFACE
    .out_mem_read_en(out_dmem_read_en),
    .out_mem_write_en(out_dmem_write_en),
    .out_mem_addr(out_dmem_addr),
    .out_mem_write_data(out_dmem_write_data)
);

//wires for
//MEMWB Registers --> Writeback Stage
wire [31:0] MEMWB_to_writeback_alu_out;
wire [31:0] MEMWB_to_writeback_mem_out;

wire MEMWB_to_writeback_mem_to_reg;
wire MEMWB_to_execute_and_writeback_write_enable;

registers_MEMWB registers_MEMWB(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_alu_out(cache_to_MEMWB_alu_out),
    .in_mem_out(cache_to_MEMWB_cache_out),

    .in_rd(cache_to_MEMWB_rd),
    .in_mem_to_reg(cache_to_MEMWB_mem_to_reg),
    .in_write_enable(cache_to_MEMWB_write_enable),

    //OUTPUT
    .out_alu_out(MEMWB_to_writeback_alu_out),
    .out_mem_out(MEMWB_to_writeback_mem_out),

    .out_rd(MEMWB_to_execute_and_writeback_rd),
    .out_mem_to_reg(MEMWB_to_writeback_mem_to_reg),
    .out_write_enable(MEMWB_to_execute_and_writeback_write_enable)
);


stage_writeback writeback(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_alu_out(MEMWB_to_writeback_alu_out),
    .in_mem_out(MEMWB_to_writeback_mem_out),

    .in_rd(MEMWB_to_execute_and_writeback_rd),
    .in_mem_to_reg(MEMWB_to_writeback_mem_to_reg),
    .in_write_enable(MEMWB_to_execute_and_writeback_write_enable),

    //OUTPUT
    .out_data(writeback_to_decode_and_execute_out_data),
    .out_rd(writeback_to_decode_rd),
    .out_write_enable(writeback_to_decode_write_enable)
);

reorder_buffer rob(
    .clk(clk),
    .reset(reset),

    //INPUT
    //FROM DECODE
    .in_allocate(decode_to_rob_allocate),
    .in_PC(IFID_to_decode_PC),
    .in_addr_miss(32'b0),
    .in_rd(decode_to_rob_rd),
    .instr_type(),

    //FROM EXECUTE REGISTERS
    .in_complete(),
    .in_complete_idx(EXMEM_to_rob_complete_idx),
    .in_complete_value(EXMEM_to_rob_complete_value),
    .in_exception(),

    //OUTPUT
    .out_ready(),
    .out_value(),
    .out_miss_addr(),           //TLB MISS          Write to rm0, rm1
    .out_PC(),                  //TODO: TLB MISS
    .out_rd(),
    .out_exception(),
    .out_instr_type(),
    .out_full(),
    .out_alloc_idx(rob_to_registers_IFID_idx)
);

endmodule
