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

    //ROB
    input [3:0]         in_complete_idx,
    input               in_instr_type,


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
    output [CACHE_LINE_SIZE-1:0] out_mem_write_data

    //ROB
    output [3:0]        out_complete_idx,
    output              out_complete
);

assign out_alu_out = in_alu_out;
assign out_rd = in_rd;
assign out_mem_to_reg = in_mem_to_reg;
assign out_write_enable = in_write_enable;
assign out_complete_idx = in_complete_idx;
assign out_complete = !out_stall && (in_instr_type != `INSTR_TYPE_LOAD);    //TODO: Manage stores. We have to see how do we do the logic
                                                                            //with the SB and the ROB

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

cache d_cache(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_addr(final_physical_address),
    .in_write_data(in_write_data),
    .in_write_en(in_write_en),
    .in_read_en(in_read_en),
    .in_funct3(in_funct3),

    //MEM IFACE
    .in_mem_read_data(in_mem_read_data),
    .in_mem_ready(in_mem_ready),

    //OUTPUT
    .out_read_data(out_read_data),
    .out_busy(out_stall),
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
    .in_funct3(),
    .in_store_inst(),

    //OUTPUT
    .out_addr(),
    .out_data(),
    .out_stall()
);

endmodule
