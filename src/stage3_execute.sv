`include "alu.sv"
`include "forwarding_unit.sv"
`include "defines2.sv"

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

    //ROB 
    input [3:0] in_complete_idx,

    //ROB Bypass
    input in_rs1_ROB_bypass,
    input [31:0] in_rs1_ROB_bypass_value,
    input in_rs2_ROB_bypass,
    input [31:0] in_rs2_ROB_bypass_value,

    //Exception vector
    input [2:0] in_exception_vector,

    //PRIV. REGS
    input [31:0] in_rm1,

    //Supervisor
    input in_supervisor_mode,


    //OUTPUT
    output [31:0] out_alu_out,
    output [31:0] out_PC,
    output [2:0] out_funct3,
    output [2:0] out_instr_type,
        //Control
    output out_branch_taken,
    output out_flush,

    output [4:0] out_rd,
    output [31:0] out_mem_in_data,
    output out_mem_write,
    output out_mem_read,
    output out_branch_inst,
    output out_mem_to_reg,
    output out_write_enable,

    //Exception
    output [2:0] out_exception_vector,

    //ROB
    output out_complete,
    output [3:0] out_complete_idx,

    output out_allocate_addr_miss,

    //ROB Bypass
    output [4:0] out_rs1_ROB,
    output [4:0] out_rs2_ROB,

    //TLBWRITE
    output out_itlb_write_enable,
    output out_dtlb_write_enable,
    output [31:0] out_tlb_virtual_address,
    output [31:0] out_tlb_physical_address,

    //Supervisor
    output out_supervisor_mode
);

assign out_rd = in_IDEX_rd;
assign out_mem_write = in_mem_write;
assign out_mem_read = in_mem_read;
assign out_branch_inst = in_branch_inst;
assign out_mem_to_reg = in_mem_to_reg;
assign out_write_enable = in_write_enable;
assign out_funct3 = in_funct3;
assign out_exception_vector = in_exception_vector; 
assign out_instr_type = in_instr_type;                          //This propagates the instruction type to the next stage
assign out_complete =   (in_exception_vector != 3'b000) ||
                        (in_instr_type == `INSTR_TYPE_IRET) || 
                        (in_instr_type == `INSTR_TYPE_MOVRM) || 
                        (in_instr_type == `INSTR_TYPE_ALU && in_instruction != 32'h00000013) && 
                        (in_opcode == `OPCODE_ALU || in_opcode == `OPCODE_ALU_IMM) || 
                        (in_opcode == `OPCODE_BRANCH || in_opcode == `OPCODE_JUMP) ||
                        (in_instr_type == `INSTR_TYPE_TLBWRITE);     
                    //This is for the ROB, to see if we write from this stage or not. We write if the instr is ALU type. Either way, we propagate the idx
assign out_complete_idx = in_complete_idx;
assign out_supervisor_mode = in_supervisor_mode;
assign out_rs1_ROB = in_rs1;
assign out_rs2_ROB = in_rs2;
assign out_allocate_addr_miss = (in_instr_type == `INSTR_TYPE_LOAD || in_instr_type == `INSTR_TYPE_STORE);

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
assign alu_operand1 =   (forwardA == 2'b10) ? in_EXMEM_alu_out :
                        in_rs1_ROB_bypass ? in_rs1_ROB_bypass_value :
                        (forwardA == 2'b01) ? in_MEMWB_out_data :
                        in_data_rs1;

assign alu_operand2 =   (forwardB == 2'b10) ? in_EXMEM_alu_out :
                        in_rs2_ROB_bypass ? in_rs2_ROB_bypass_value :
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
    .in_rm1(in_rm1),

    //OUTPUT
    .alu_out(out_alu_out),
    .out_PC(out_PC),
    .branch_taken(out_branch_taken)
);

assign out_itlb_write_enable = in_instruction[6:0] == `OPCODE_TLBWRITE && in_instruction[14:12] == `ITLBWRITE_FUNCT3;
assign out_dtlb_write_enable = in_instruction[6:0] == `OPCODE_TLBWRITE && in_instruction[14:12] == `DTLBWRITE_FUNCT3;
assign out_tlb_virtual_address = alu_operand1;
assign out_tlb_physical_address = alu_operand2;
    
assign out_flush = out_branch_taken;

endmodule
