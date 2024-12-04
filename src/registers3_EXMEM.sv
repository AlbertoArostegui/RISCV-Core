
module registers_EXMEM(
    input clk,
    input reset,

    //INPUT
    input [31:0] in_alu_out,
    input [31:0] in_new_PC,
    input in_branch_taken,
    
    input [4:0] in_rd,
    input [31:0] in_mem_data,
    input in_mem_write,
    input in_mem_read,
    input in_branch_inst,
    input in_mem_to_reg,
    input in_write_enable,

    //OUTPUT
    output reg [31:0] out_alu_out,
    output reg [31:0] out_new_PC,
    output reg out_branch_taken,

    output reg [4:0] out_rd,
    output reg [31:0] out_mem_data,
    output reg out_mem_write,
    output reg out_mem_read,
    output reg out_branch_inst,
    output reg out_mem_to_reg,
    output reg out_write_enable
);

initial begin
    out_alu_out = 0;
    out_new_PC = 0;
    out_branch_taken = 0;
    out_rd = 0;
    out_mem_write = 0;
    out_mem_read = 0;
    out_mem_to_reg = 0;
    out_write_enable = 0;
end

always @(posedge clk) begin
    out_alu_out <= in_alu_out;
    out_new_PC <= in_new_PC;
    out_branch_taken <= in_branch_taken;

    out_alu_out <= in_alu_out;
    out_new_PC <= in_new_PC;
    out_branch_taken <= in_branch_taken;

    out_rd <= in_rd;
    out_mem_data <= in_mem_data;
    out_mem_write <= in_mem_write;
    out_mem_read <= in_mem_read;
    out_branch_inst <= in_branch_inst;
    out_mem_to_reg <= in_mem_to_reg;
    out_write_enable <= in_write_enable;

end

endmodule
