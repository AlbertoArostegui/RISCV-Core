module registers_MEMWB(
    input clk,
    input reset,

    //INPUT
    input [31:0] in_alu_out,
    input [31:0] in_mem_out,

    input [4:0] in_rd,
    input in_mem_to_reg,
    input in_write_enable,

    //ROB
    input in_complete,
    input [3:0] in_complete_idx,
    input [2:0] in_instr_type,

    //OUTPUT
    output reg [31:0] out_alu_out,
    output reg [31:0] out_mem_out,

    output reg [4:0] out_rd,
    output reg out_mem_to_reg,
    output reg out_write_enable,

    //ROB
    output reg out_complete,
    output reg [3:0] out_complete_idx,
    output reg [2:0] out_instr_type
);

initial begin
    out_alu_out = 0;
    out_mem_out = 0;
    out_rd = 0;
    out_mem_to_reg = 0;
    out_write_enable = 0;
    out_instr_type = 0;
end

always @(posedge clk) begin
    if (reset) begin
        out_alu_out <= 0;
        out_mem_out <= 0;
        out_rd <= 0;
        out_mem_to_reg <= 0;
        out_write_enable <= 0;       
        //ROB
        out_complete <= 0;
        out_complete_idx <= 0;
        out_instr_type <= 0;
    end
    out_alu_out <= in_alu_out;
    out_mem_out <= in_mem_out;

    out_rd <= in_rd;
    out_mem_to_reg <= in_mem_to_reg;
    out_write_enable <= in_write_enable;

    //ROB
    out_complete <= in_complete;
    out_complete_idx <= in_complete_idx;
    out_instr_type <= in_instr_type;
end

endmodule
