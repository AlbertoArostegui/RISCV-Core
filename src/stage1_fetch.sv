`include "imemory.sv"

//Here everything should be a wire (its comb. logic)
module stage_fetch (
    input clk,
    input reset,

    //INPUT
    input branch_taken,
    input [31:0] new_pc,
    input pc_write_disable,

    //OUTPUT
    output [31:0] out_PC,
    output [31:0] out_instruction
);

reg [31:0] PC;
reg [31:0] init;

assign out_PC = PC;

initial begin 
    init = 32'h0;
    PC = 32'h0;
end

always @(posedge clk or posedge reset) begin
    if (reset) 
        PC <= init;
    else if (!pc_write_disable) begin
        if (branch_taken)
            PC <= new_pc;
        else
            PC <= PC + 4;
    end
end

wire [31:0] mem_addr = PC >> 2; //The aim is to select the word address

imemory imemory(
    .clk(clk),
    .mem_addr(mem_addr),
    .inst_out(out_instruction)
);

endmodule
