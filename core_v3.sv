`include "defines.v"
`include "stage1_fetch"

module core (
    input clk,
    input reset
)

//FETCH STAGE
wire [31:0] fetch_to_registers_pc;
wire [31:0] fetch_to_registers_inst;

stage_fetch fetch(
    .clk(clk),    
    .reset(reset),
    .branch_taken(),
    .new_pc(),
    .out_pc(fetch_to_registers_pc),
    .inst_out(fetch_to_registers_inst)
);

