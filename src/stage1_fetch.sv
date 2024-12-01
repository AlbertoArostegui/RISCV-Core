`include "cache.sv"
//Here everything should be a wire (its comb. logic)
module stage_fetch #(
    parameter CACHE_LINE_SIZE = 128
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
    output [31:0] out_instruction

    //MEM IFACE
    output out_mem_read_en,
    output out_mem_write_en,
    output [31:0] out_mem_addr,
    output [CACHE_LINE_SIZE-1:0] out_mem_write_data
);

reg [31:0] PC;
reg [31:0] init;

assign out_PC = PC;

initial begin 
    init = 32'h0;
    PC = 32'h0;
end

always @(posedge clk or posedge reset) begin
    if (reset) 
        PC <= init;
    else if (!pc_write_disable) begin
        if (branch_taken)
            PC <= new_pc;
        else
            PC <= PC + 4;
    end
end

wire [31:0] mem_addr = PC >> 2; //The aim is to select the word address

imemory imemory(
    .clk(clk),
    .mem_addr(mem_addr),
    .inst_out(out_instruction)
);

cache cache(
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_read_en(in_read_en),
    .in_write_en(in_write_en),
    .in_addr(mem_addr),
    .in_write_data(in_write_data),
    .in_funct3(3'b010),

    //MEM IFACE
    .in_mem_read_data(in_mem_read_data),
    .in_mem_ready(in_mem_ready),
    //OUTPUT
    .out_read_data(out_instruction),
    .out_busy(out_busy),
    .out_hit(),

    //MEM IFACE
    .out_mem_read_en(out_mem_read_en),
    .out_mem_write_en(out_mem_write_en),
    .out_mem_addr(out_mem_addr),
    .out_mem_write_data(out_mem_write_data)
);

endmodule
