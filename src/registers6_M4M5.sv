module registers_M4M5(
    input clk,
    input reset,

    //INPUT
    input [31:0]            in_mul_out,

    input [3:0]             in_rob_idx,
    input [2:0]             in_exception_vector,        //Exceptions
    input [2:0]             in_instr_type,

    //OUTPUT
    output reg [31:0]       out_mul_out,

    output reg [3:0]        out_rob_idx,
    output reg [2:0]        out_exception_vector,
    output reg [2:0]        out_instr_type
);

always @(posedge clk) begin
    if (reset) begin
        out_mul_out <= 0;
        out_rob_idx <= 0;
        out_exception_vector <= 0;
        out_instr_type <= 0; //Not mul
    end else begin
        out_mul_out <= in_mul_out;
        out_rob_idx <= in_rob_idx;
        out_exception_vector <= in_exception_vector;
        out_instr_type <= in_instr_type;
    end
end

endmodule
