`include "dmemory.sv"

module stage_memory(
    input clk,
    input reset,

    //INPUT
    //Memory interaction
    input [31:0] in_alu_out, //Address
    input [31:0] in_mem_data,
    
    //Control
    input in_mem_write,
    input in_mem_read,

    //Passing by
    input [4:0] in_rd,
    input in_mem_to_reg,
    input in_write_enable,

    //OUTPUT
    output [31:0] out_alu_out,
    output [31:0] out_mem_out,
    output [4:0] out_rd,
    output out_mem_to_reg,
    output out_write_enable
);
    assign out_alu_out = in_alu_out;
    assign out_rd = in_rd;
    assign out_mem_to_reg = in_mem_to_reg;
    assign out_write_enable = in_write_enable;

    dmemory dmemory(
        .clk(clk),
        .reset(reset),

        //INPUT
        .in_mem_addr(in_alu_out),
        .in_mem_data(in_mem_data),
        .in_mem_write(in_mem_write),
        .in_mem_read(in_mem_read),

        //OUTPUT
        .out_data(out_mem_out)
    );


endmodule
