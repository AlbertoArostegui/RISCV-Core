`include "cache.sv"
//Here everything should be a wire (its comb. logic)
module stage_fetch #(
    parameter CACHE_LINE_SIZE = 128,
    parameter INIT_ADDR = 32'h200
) (
    input clk,
    input reset,

    //INPUT
    input branch_taken,
    input [31:0] new_pc,
    input pc_write_disable,

    //MEM IFACE
    input [CACHE_LINE_SIZE-1:0] in_mem_read_data,
    input in_mem_ready,

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
    output [2:0] out_exception_vector
);

reg [31:0] PC;

assign out_PC = PC;
assign out_exception_vector = 3'b0;

initial begin 
    PC = 32'h0;
end

always @(posedge clk or posedge reset) begin
    if (reset) 
        PC <= INIT_ADDR;
    else if (!pc_write_disable) begin
        if (branch_taken)
            PC <= new_pc;
        else if (!out_stall)
            PC <= PC + 4;
    end
end

// Instantiate the ITLB
itlb itlb (
    .clk(clk),
    .reset(reset),
    .virtual_address(PC),
    .physical_address(itlb_physical_address),
    .tlb_hit(itlb_hit)
);

wire [31:0] tlb_miss_physical_address;
wire tlb_update;

tlb_miss tlb_miss (
    .clk(clk),
    .reset(reset),
    .virtual_address(PC),
    .tlb_miss_detected(~itlb_hit),
    .os_offset(32'h1000),
    .tlb_miss_physical_address(tlb_miss_physical_address),
    .tlb_update(tlb_update)
);

wire [31:0] final_physical_address = itlb_hit ? itlb_physical_address : tlb_miss_physical_address;

wire [31:0] in_write_data;      

cache icache(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_read_en(1'b1),
    .in_write_en(in_write_en),
    .in_addr(final_physical_address),
    .in_write_data(in_write_data),
    .in_funct3(3'b010),

    //MEM IFACE
    .in_mem_read_data(in_mem_read_data),
    .in_mem_ready(in_mem_ready),
    //OUTPUT
    .out_read_data(out_instruction),
    .out_busy(out_stall),
    .out_hit(),

    //MEM IFACE
    .out_mem_read_en(out_mem_read_en),
    .out_mem_write_en(out_mem_write_en),
    .out_mem_addr(out_mem_addr),
    .out_mem_write_data(out_mem_write_data)
);
endmodule
