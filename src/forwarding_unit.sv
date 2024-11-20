module forwarding_unit(
    input clk,
    input reset,

    //INPUT
    input [4:0] in_IDEX_rs1,    //From IDEX
    input [4:0] in_IDEX_rs2,    //From IDEX
    input [4:0] in_EXMEM_rd,    //From EXMEM
    input [4:0] in_MEMWB_rd,
    input in_EXMEM_write_enable,
    input in_MEMWB_write_enable,

    //OUTPUT
        //Control for the MUX in the alu src
    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);

    always @(*) begin
        // Default values
        forwardA = 2'b00;
        forwardB = 2'b00;
        
        //EX Hazard
        if ((in_EXMEM_rd != 0) && (in_EXMEM_rd == in_IDEX_rs1) && (in_EXMEM_write_enable)) begin
            forwardA = 2'b10;  //Forward from EXMEM
        end
        if ((in_EXMEM_rd != 0) && (in_EXMEM_rd == in_IDEX_rs2) && (in_EXMEM_write_enable)) begin
            forwardB = 2'b10;  //Forward from EXMEM
        end
        //MEM Hazard
        
        if ((in_MEMWB_rd != 0) && (in_MEMWB_rd == in_IDEX_rs1) && (in_MEMWB_write_enable) && 
            !(in_EXMEM_write_enable && (in_EXMEM_rd != 0) && (in_EXMEM_rd == in_IDEX_rs1))) begin
            forwardA = 2'b01;
        end
        if ((in_MEMWB_rd != 0) && (in_MEMWB_rd == in_IDEX_rs2) && (in_MEMWB_write_enable) && 
            !(in_EXMEM_write_enable && (in_EXMEM_rd != 0) && (in_EXMEM_rd == in_IDEX_rs2))) begin
            forwardB = 2'b01;
        end
    end


endmodule
