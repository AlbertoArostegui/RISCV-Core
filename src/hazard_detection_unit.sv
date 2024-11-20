module hazard_detection_unit (
    //INPUT
    input wire [4:0] in_IFID_rs1,
    input wire [4:0] in_IFID_rs2,
    input wire [4:0] in_IDEX_rd,
    input wire in_IDEX_mem_read,

    //OUTPUT
    output reg out_stall,
    output reg out_pc_write_disable,
    output reg out_IFID_write_disable,
    output reg out_control_src
);

initial begin
    out_stall <= 0;
    out_pc_write_disable <= 0;
    out_IFID_write_disable <= 0;
    out_control_src <= 0;
end

always @(*) begin
    if (in_IDEX_mem_read && ((in_IDEX_rd == in_IFID_rs1) || (in_IDEX_rd == in_IFID_rs2))) begin
        out_stall <= 1;
        out_pc_write_disable <= 1;
        out_IFID_write_disable <= 1;
        out_control_src <= 0;
    end else begin
        out_stall <= 0;
        out_pc_write_disable <= 0;
        out_IFID_write_disable <= 0;
        out_control_src <= 1;
    end
end

endmodule