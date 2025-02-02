`include "store_buffer.sv"
`include "defines2.sv"

module stage_cache #(
    parameter CACHE_LINE_SIZE = 128
)(
    input clk,
    input reset,

    //INPUT
    input [31:0]        in_alu_out, //in_addr
    input [31:0]        in_write_data,
    input [2:0]         in_exception_vector,

    //Control
    input               in_write_en,
    input               in_read_en,
    input [2:0]         in_funct3,

    //Control passing by
    input [4:0]         in_rd,
    input               in_mem_to_reg,
    input               in_write_enable,

    //MEM IFACE
    input wire [CACHE_LINE_SIZE-1:0] in_mem_read_data,
    input wire          in_mem_ready,

    //FOR ROB
    //Here the difference with Ex. is that we pass idx to ROB as if it was completed (same as Ex.), but won't commit to cache until ROB issues the completion flag.
    //So we need 2 different idxs. One for sending to rob as "ready to commit" and the other to know when and which entry to commit when ROB signals it.
    input [3:0]         in_allocate_idx,
    input [2:0]         in_instr_type,

    //FROM ROB
    input               in_complete,
    input [3:0]         in_complete_idx,
    input [2:0]         in_instr_type_ROB,
    input [2:0]         in_exception_vector_ROB,

    //Supervisor
    input               in_supervisor_mode,

    //TLBWRITE
    input              in_dtlb_write_enable,
    input [31:0]       in_tlb_virtual_address,
    input [31:0]       in_tlb_physical_address,

    //OUTPUT
    output [31:0]       out_alu_out,
    output [31:0]       out_read_data,

    //Stall
    output              out_stall,   

    //Control passing by
    output [4:0]        out_rd,
    output              out_mem_to_reg,
    output              out_write_enable,

    //MEM IFACE
    output              out_mem_read_en,
    output              out_mem_write_en,
    output [31:0]       out_mem_addr,
    output [CACHE_LINE_SIZE-1:0] out_mem_write_data,

    //ROB
    output [3:0]        out_complete_idx,
    output              out_complete,
    output [2:0]        out_exception_vector,
    output [2:0]        out_instr_type
);

assign out_alu_out = in_alu_out;
assign out_rd = in_rd;
assign out_mem_to_reg = in_mem_to_reg;
assign out_write_enable = in_write_enable;
assign out_instr_type = in_instr_type;
assign out_complete_idx = in_allocate_idx; //We pass "ready to commit" to the ROB.
assign out_complete = !out_stall && (in_instr_type == `INSTR_TYPE_LOAD || in_instr_type == `INSTR_TYPE_STORE);   
assign out_exception_vector = in_read_en ? ((sb_bypass_found) ? 3'b000 : 
                              (tlb_hit) ? 3'b000 : `EXCEPTION_TYPE_DTLBMISS) : 
                              (in_complete && !tlb_hit) ? `EXCEPTION_TYPE_DTLBMISS :
                              3'b000; //Assuming we only generate exceptions in this stage if we have a TLB miss 
wire [31:0] tlb_addr =  (in_read_en && !sb_bypass_found) ? in_alu_out : 
                        (write_sb_entry_to_cache) ? sb_to_tlb_addr : 
                        in_alu_out;

tlb dtlb (
    .clk(clk),
    .reset(reset),
    
    //INPUT
    .in_supervisor_mode(in_supervisor_mode),
    .in_virtual_address(tlb_addr),

    .in_write_enable(in_dtlb_write_enable),
    .in_write_virtual_address(in_tlb_virtual_address),
    .in_write_physical_address(in_tlb_physical_address),

    
    //OUTPUT
    .out_fault_addr(),
    .out_physical_address(tlb_to_cache_physical_address),
    .out_tlb_hit(tlb_hit),
    .out_exception_vector(dtlb_exception_vector)
);

//TLB
wire [2:0] dtlb_exception_vector;
wire [31:0] tlb_to_cache_physical_address;
wire tlb_hit;

//Combined stall
wire cache_stall;
wire sb_stall;
assign out_stall = cache_stall | sb_stall;

wire [31:0]     sb_to_tlb_addr;
wire [31:0]     sb_to_cache_data;
wire [2:0]      sb_to_cache_funct3; 
wire            write_sb_entry_to_cache;

//When loading, we must look for bypass from SB. It could save us from having to stall to look for the line in memory.
wire sb_bypass_found;
wire [31:0] cache_data_out;
assign out_read_data = sb_bypass_found ? sb_to_cache_data : cache_data_out;

cache d_cache(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_tlb_hit(tlb_hit),
    .in_addr(tlb_to_cache_physical_address),
    .in_write_data(sb_to_cache_data),
    .in_write_en(write_sb_entry_to_cache),
    .in_read_en(in_read_en),
    .in_bypass_found(sb_bypass_found),
    .in_funct3(sb_to_cache_funct3),

    //MEM IFACE
    .in_mem_read_data(in_mem_read_data),
    .in_mem_ready(in_mem_ready),

    //OUTPUT
    .out_read_data(cache_data_out),
    .out_busy(cache_stall),
    .out_hit(),
    .out_cache_ack(cache_write_ack),

    //MEM IFACE
    .out_mem_read_en(out_mem_read_en),
    .out_mem_write_en(out_mem_write_en),
    .out_mem_addr(out_mem_addr),
    .out_mem_write_data(out_mem_write_data)
);

wire complete_store = in_complete && in_instr_type_ROB == `INSTR_TYPE_STORE;
wire cache_write_ack;

store_buffer store_buffer(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_addr(in_alu_out),
    .in_data(in_write_data),
    .in_funct3(in_funct3),
    .in_store_instr(in_write_en),
    .in_load_instr(in_read_en),
    .in_cache_stall(cache_stall),
    .in_cache_ack(cache_write_ack),
    
    //ROB
    .in_rob_idx(in_allocate_idx),  //Allocate
    .in_complete(complete_store),  
    .in_complete_idx(in_complete_idx),
    .in_exception_vector(in_exception_vector_ROB),


    //OUTPUT
    .out_addr(sb_to_tlb_addr),
    .out_data(sb_to_cache_data),
    .out_funct3(sb_to_cache_funct3),
    .out_hit(sb_bypass_found),
    .out_write_to_cache(write_sb_entry_to_cache),
    .out_stall(sb_stall)
);

endmodule
