module registers_EXWB(
    input clk,
    input reset,

    //INPUT
    input [31:0]            in_alu_out,                 //Value
    input [4:0]             in_rd,                      //Register destination
    input                   in_mem_to_reg,
    input [2:0]             in_exception_vector,        //Exceptions


    //OUTPUT
    output reg [31:0]       out_alu_out,
    output reg [4:0]        out_rd,
    output reg              out_mem_to_reg,
    output reg [2:0]        out_exception_vector,
);

endmodule