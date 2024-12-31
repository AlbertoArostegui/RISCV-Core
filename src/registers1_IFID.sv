module registers_IFID(
    input clk,
    input reset,
    input [31:0] in_instruction,
    input [31:0] in_PC,

    //CONTROL
    input in_IFID_write_disable,
    input in_IFID_flush,
    input in_i_cache_stall,
    input in_d_cache_stall,

    //Exception vector
    input [2:0] in_exception_vector,

    //ROB
    input [3:0] in_complete_idx,

    //OUTPUT
    output reg [31:0] out_instruction,
    output reg [31:0] out_PC,

    //ROB
    output reg [3:0] out_complete_idx,
    output reg out_wait_stall,

    //Exception vector
    output reg [2:0] out_exception_vector
);

    initial begin
        out_PC = 0;
        out_instruction = 0;
    end

    always @(posedge clk) begin
        if (reset || in_IFID_flush || in_i_cache_stall) begin //Flush IFID: sends NOPs down the pipeline
            out_instruction <= 32'b0;
            out_PC <= 32'b0;
            out_complete_idx <= 4'b0;
            out_exception_vector <= 3'b0;
            out_wait_stall <= 1'b1;
        end else if (!in_IFID_write_disable && !in_d_cache_stall) begin
            out_PC <= in_PC;
            out_instruction <= in_instruction;
            out_complete_idx <= in_complete_idx;
            out_exception_vector <= in_exception_vector;
            out_wait_stall <= 1'b0;
        end
    end

endmodule
