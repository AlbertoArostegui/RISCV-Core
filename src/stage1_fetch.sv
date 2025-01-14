`include "cache.sv"
`include "tlb.sv"
`include "privileged_regs.sv"
`include "defines2.sv"
module stage_fetch #(
    parameter CACHE_LINE_SIZE = 128,
    parameter INIT_ADDR = 32'h1000
) (
    input clk,
    input reset,

    //INPUT
    input branch_taken,
    input [31:0] new_pc,
    input pc_write_disable,
    input in_d_cache_stall,

    //MEM IFACE
    input [CACHE_LINE_SIZE-1:0] in_mem_read_data,
    input in_mem_ready,

    //ROB Exception
    input [2:0] in_exception_vector,
    input [31:0] in_rob_fault_PC,
    input [31:0] in_rob_fault_addr,

    //ROB Supervisor
    input in_priv_write_enable,
    input [2:0] in_priv_rm_idx,
    input [31:0] in_priv_write_data,

    //TLBWRITE
    input in_itlb_write_enable,
    input [31:0] in_tlb_virtual_address,
    input [31:0] in_tlb_physical_address,


    //OUTPUT
    output [31:0] out_PC,
    output [31:0] out_instruction,
    output out_stall,

    //MEM IFACE
    output out_mem_read_en,
    output out_mem_write_en,
    output [31:0] out_mem_addr,
    output [CACHE_LINE_SIZE-1:0] out_mem_write_data,

    //Exception
    output [2:0] out_exception_vector,

    //PRIV. REGS
    output [31:0] out_rm1,

    //Supervisor
    output out_supervisor_mode
);

reg [31:0] PC;

assign out_PC = PC;
assign out_supervisor_mode = supervisor_mode;

initial begin 
    PC = 32'h0;
end

wire [31:0] next_pc = (overwrite_PC) ? overwrite_PC_addr :
                (branch_taken) ? new_pc :
                PC + 4;

always @(posedge clk or posedge reset) begin
    if (reset) 
        PC <= INIT_ADDR;
    else if (!pc_write_disable && !in_d_cache_stall) begin
        if (overwrite_PC)
            PC <= overwrite_PC_addr;
        else if (branch_taken)
            PC <= new_pc;
        else if (!out_stall)
            PC <= PC + 4;
    end else if (in_d_cache_stall && branch_taken) begin
        PC <= new_pc;
    end
end

wire supervisor_mode;
wire [31:0] itlb_physical_address;
wire itlb_hit;
wire overwrite_PC;
wire [31:0] overwrite_PC_addr;
wire [31:0] out_cache_instr;
wire [2:0] service_exception_vector;

assign out_instruction = itlb_hit ? out_cache_instr : 32'h0;
assign out_exception_vector = itlb_hit ? 3'b0 : `EXCEPTION_TYPE_ITLBMISS;

privileged_regs privileged_regs(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_rm_idx(in_priv_rm_idx),
    .in_write_enable(in_priv_write_enable),
    .in_write_data(in_priv_write_data),
    .in_exception_vector(in_exception_vector),
    //FROM ROB
    .in_fault_pc(in_rob_fault_PC),
    .in_fault_addr(in_rob_fault_addr),
    .in_additional_info(),

    //OUTPUT
    .out_new_address(overwrite_PC_addr),
    .out_overwrite_PC(overwrite_PC),
    .out_supervisor_mode(supervisor_mode),
    .out_exception_vector(service_exception_vector),
    .out_rm1(out_rm1)
);

tlb itlb (
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_supervisor_mode(supervisor_mode),
    .in_virtual_address(PC),

    .in_write_enable(in_itlb_write_enable),
    .in_write_virtual_address(in_tlb_virtual_address),
    .in_write_physical_address(in_tlb_physical_address),

    //OUTPUT
    .out_fault_addr(),
    .out_physical_address(itlb_physical_address),
    .out_tlb_hit(itlb_hit),
    .out_exception_vector()
);

cache icache(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_tlb_hit(itlb_hit),
    .in_read_en(1'b1),
    .in_bypass_found(1'b0),
    .in_write_en(1'b0),
    .in_addr(itlb_physical_address),
    .in_write_data(32'h0),
    .in_funct3(3'b010),

    //MEM IFACE
    .in_mem_read_data(in_mem_read_data),
    .in_mem_ready(in_mem_ready),


    //OUTPUT
    .out_read_data(out_cache_instr),
    .out_busy(out_stall),
    .out_hit(),

    //MEM IFACE
    .out_mem_read_en(out_mem_read_en),
    .out_mem_write_en(out_mem_write_en),
    .out_mem_addr(out_mem_addr),
    .out_mem_write_data(out_mem_write_data)
);
endmodule
