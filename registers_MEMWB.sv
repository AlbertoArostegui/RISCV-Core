module registers_MEMWB(
    input clk,
    input reset,

    //INPUT
    input [31:0] in_alu_out,
    input [31:0] in_mem_out,

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

initial begin
    out_alu_out = 0;
    out_mem_out = 0;
    out_rd = 0;
    out_mem_to_reg = 0;
    out_write_enable = 0;
end

always @(posedge clk) begin
    in_alu_out <= out_alu_out;
    in_mem_out <= out_mem_out;

    in_rd <= out_rd;
    in_mem_to_reg <= out_mem_to_reg;
    in_write_enable <= out_write_enable;
end

endmodule
