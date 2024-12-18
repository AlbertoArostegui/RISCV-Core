module registers3_EXEX(
    input clk,
    input reset,

    //INPUT
    input [31:0]            in_data_a,
    input [31:0]            in_data_b,

    input [3:0]             in_rob_idx,
    input [2:0]             in_exception_vector,        //Exceptions


    //OUTPUT
    output reg [31:0]       out_data_a,
    output reg [31:0]       out_data_b,

    output reg [3:0]        out_rob_idx,
    output reg [2:0]        out_exception_vector
);

always @(posedge clk) begin
    if (reset) begin
        out_rob_idx <= 0;
        out_exception_vector <= 0;
    end else begin
        out_rob_idx <= in_rob_idx;
        out_exception_vector <= in_exception_vector;
    end
end

endmodule