//`include "cache.sv"
`include "store_buffer.sv"

module stage_cache #(
    parameter CACHE_LINE_SIZE = 128
)(
    input clk,
    input reset,

    //INPUT
    input [31:0]        in_alu_out, //in_addr
    input [31:0]        in_write_data,

    //Control
    input               in_write_en,
    input               in_read_en,
    input [2:0]         in_funct3,
    input               mode, // 0 for INSTRUCTION, 1 for DATA

    //Control passing by
    input [4:0]         in_rd,
    input               in_mem_to_reg,
    input               in_write_enable,

    //MEM IFACE
    input wire [CACHE_LINE_SIZE-1:0] in_mem_read_data,
    input wire          in_mem_ready,

    //FOR ROB
    //Here the difference with Ex. is that we pass idx to ROB as if it was completed (same as Ex.), but won't commit to cache until ROB issues the completion flag.
    //So we need 2 different idxs. One for sending to rob as "ready to commit" and the other to know which to commit when ROB signals it.
    input [3:0]         in_allocate_idx,
    input [2:0]         in_instr_type,

    //FROM ROB
    input               in_complete,
    input [3:0]         in_complete_idx,
    input [2:0]         in_instr_type_ROB,
    input [2:0]         in_exception_vector,


    //OUTPUT
    output [31:0]       out_alu_out,
    output [31:0]       out_read_data,
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
    output [2:0]        out_instr_type
);

assign out_alu_out = in_alu_out;
assign out_rd = in_rd;
assign out_mem_to_reg = in_mem_to_reg;
assign out_write_enable = in_write_enable;
assign out_instr_type = in_instr_type;
assign out_complete_idx = in_allocate_idx; //We pass "ready to commit" to the ROB.
assign out_complete = !out_stall && (in_instr_type == `INSTR_TYPE_LOAD || in_instr_type == `INSTR_TYPE_STORE);   
/*
// Instantiate the DTLB
dtlb dtlb (
    .clk(clk),
    .reset(reset),
    .virtual_address(in_alu_out),
    .physical_address(dtlb_physical_address),
    .tlb_hit(dtlb_hit)
);

// Handle TLB miss
wire [31:0] tlb_miss_physical_address;
wire tlb_update;

tlb_miss tlb_miss (
    .clk(clk),
    .reset(reset),
    .virtual_address(in_alu_out),
    .tlb_miss_detected(~dtlb_hit),
    .os_offset(32'h1000), // Example offset, adjust as needed
    .tlb_miss_physical_address(tlb_miss_physical_address),
    .tlb_update(tlb_update)
);

wire [31:0] final_physical_address = dtlb_hit ? dtlb_physical_address : tlb_miss_physical_address;
*/

//Combined stall
wire cache_stall;
wire sb_stall;
assign out_stall = cache_stall | sb_stall;

wire [31:0]     sb_to_cache_addr;
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
    .in_addr(sb_to_cache_addr),
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

    //MEM IFACE
    .out_mem_read_en(out_mem_read_en),
    .out_mem_write_en(out_mem_write_en),
    .out_mem_addr(out_mem_addr),
    .out_mem_write_data(out_mem_write_data)
);

store_buffer store_buffer(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_addr(in_alu_out),
    .in_data(in_write_data),
    .in_funct3(in_funct3),
    .in_store_instr(in_write_en),
    .in_load_instr(in_read_en),
    
    //ROB
    .in_rob_idx(in_allocate_idx),  //Allocate
    .in_complete(in_instr_type_ROB == `INSTR_TYPE_STORE),      //TODO: Can't use in_complete directly from the ROB in core.sv. I don't know why, the execution simply doesn't go past cycle 17
    .in_complete_idx(in_complete_idx),
    .in_exception_vector(in_exception_vector),


    //OUTPUT
    .out_addr(sb_to_cache_addr),
    .out_data(sb_to_cache_data),
    .out_funct3(sb_to_cache_funct3),
    .out_hit(sb_bypass_found),
    .out_write_to_cache(write_sb_entry_to_cache),
    .out_stall(sb_stall)
);

endmodule
