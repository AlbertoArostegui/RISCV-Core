module registers_M5WB (
    input clk,
    input reset,

    //INPUT
    input [31:0]            in_mul_out,

    input [3:0]             in_complete_idx,
    input                   in_complete,
    input [2:0]             in_exception_vector,        //Exceptions


    //OUTPUT
    output reg [31:0]       out_mul_out,
    output reg [3:0]        out_complete_idx,
    output reg              out_complete,
    output reg [2:0]        out_exception_vector
);

always @(posedge clk) begin
    if (reset) begin
        out_mul_out <= 0;
        out_complete_idx <= 0;
        out_complete <= 0;
        out_exception_vector <= 0;
    end else begin
        out_mul_out <= in_mul_out;
        out_complete_idx <= in_complete_idx;
        out_complete <= in_complete;
        out_exception_vector <= in_exception_vector;
    end
end

endmodule
