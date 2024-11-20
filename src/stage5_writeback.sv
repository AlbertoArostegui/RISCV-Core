module stage_writeback(
    input clk,
    input reset,

    //INPUT
    input [31:0] in_alu_out,
    input [31:0] in_mem_out,
    
    input [4:0] in_rd,
    input in_mem_to_reg,
    input in_write_enable,

    //OUTPUT
    output reg [31:0] out_data,
    output reg [4:0] out_rd,
    output reg out_write_enable
);

always @(*) begin
    out_data <= (in_mem_to_reg) ? in_mem_out : in_alu_out;
    out_rd <= in_rd;
    out_write_enable <= in_write_enable;
end

endmodule
