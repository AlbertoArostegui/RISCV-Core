`include "defines2.sv"
module stage_multiply (
    input clk,
    input reset,

    //INPUT
    input [31:0]            in_mul_out,

    input [2:0]             in_instr_type,
    input [3:0]             in_rob_idx,
    input [2:0]             in_exception_vector,        //Exceptions


    //OUTPUT
    output [31:0]           out_mul_out,

    output [3:0]            out_rob_idx,
    output                  out_complete, 
    output [2:0]            out_exception_vector
);

assign out_complete = (in_instr_type == `INSTR_TYPE_MUL);
assign out_rob_idx = in_rob_idx;
assign out_exception_vector = in_exception_vector;
assign out_mul_out = in_mul_out;

endmodule