`include "register_file.sv"

module stage_decode(
    input clk,
    input reset,
    input instruction,
    input write_enable,
    input [4:0] write_reg,
    input [31:0] write_data,

    output [31:0] data_a,
    output [31:0] data_b
);

wire [4:0] inst_a;
wire [4:0] inst_b;

assign inst_a;
assign inst_b;

register_file RF(
    .clk(clk), 
    .reset(reset),
    .we(write_enable),
    .wreg(write_reg),
    .wdata(write_data)
);

endmodule
