`include "defines.v"
`include "imemory.v"

//Here everything should be a wire (its comb. logic)
module stage_fetch (
    input clk,
    input reset,
    input branch_taken,
    input [31:0] new_pc,
    output [31:0] out_pc,
    output [31:0] inst_out
);

reg [31:0] PC;
reg [31:0] init;

assign out_pc = PC;

initial begin 
    init = `PC_INITIAL
end

always @(posedge clk or posedge reset) begin
    if (reset) 
        PC = init;
    if (branch_taken)
        PC <= new_pc;
    else
        PC <= PC + 4;
end


memory imemory(
    .mem_addr(out_pc),
    .inst_out(inst_out)
);

endmodule
