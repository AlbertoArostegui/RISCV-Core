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

    //OUTPUT
    output reg [31:0] out_instruction,
    output reg [31:0] out_PC
);

    initial begin
        out_PC = 0;
        out_instruction = 0;
    end

    always @(posedge clk) begin
        if (reset || in_IFID_flush || in_i_cache_stall) begin
            out_instruction <= 32'b0;
            out_PC <= 32'b0;
        end else if (!in_IFID_write_disable && !in_d_cache_stall) begin
            out_PC <= in_PC;
            out_instruction <= in_instruction;
        end
    end

endmodule
