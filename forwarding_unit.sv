module forwarding_unit(
    input clk,
    input reset,

    //INPUT
    input [4:0] in_IDEX_rs1,    //From IDEX
    input [4:0] in_IDEX_rs2,    //From IDEX
    input [4:0] in_EXMEM_rd,    //From EXMEM
    input [4:0] in_MEMWB_rd,

    //OUTPUT
        //Control for the MUX in the alu src
    output forwardA,
    output forwardB
);

endmodule
