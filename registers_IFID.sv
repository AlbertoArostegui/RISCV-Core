module registers_IFID(
    input clk,
    input reset,
    input [31:0] in_instruction,
    input [31:0] in_PC,

    output [31:0] reg out_instruction,
    output [31:0] reg out_PC
);

    initial begin
        out_PC = 0;
        out_instruction = 0;
    end

    always @(posedge clk) begin
        out_PC <= in_PC;
        out_instruction <= in_instruction;
    end

endmodule
