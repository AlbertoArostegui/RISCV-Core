module register_file(
    input clk,
    input reset,
    input we,
    input [4:0] wreg,
    input [31:0] wdata,
    input [4:0] reg_a,
    input [4:0] reg_b,
    output reg [31:0] out_data_a,
    output reg [31:0] out_data_b
);

reg [31:0] registers [0:31];

initial begin
    for (integer i=0; i <32; i++) 
        registers[i] = i;
end

always @(*) begin
    if (we && wreg != 0) begin
        out_data_a = (reg_a == wreg) ? wdata : registers[reg_a];
        out_data_b = (reg_b == wreg) ? wdata : registers[reg_b];
    end else begin
        out_data_a = registers[reg_a];
        out_data_b = registers[reg_b];
    end
end

always @(posedge clk) begin
    if (we && wreg != 0) begin
        registers[wreg] <= wdata;
    end
end
endmodule


