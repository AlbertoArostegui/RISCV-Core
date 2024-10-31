module register_file(
    input clk,
    input reset,
    input we,
    input [4:0] wreg,
    input [31:0] wdata,
    input [4:0] reg_a,
    input [4:0] reg_b,
    output reg [31:0] out_data_a,
    output reg [31:0] out_data_b,
);

wire [31:0] out_data;

reg [31:0] registers [0:31];

initial begin
    for (i=0; i <32, i++) 
        registers[i] = 0;
end

always @(*) begin
    out_data_a <= registers[reg_a];
    out_data_b <= registers[reg_b];
end

always @(posedge clk) begin
    if (we) begin
        registers[wreg] = wdata;
    end
end
endmodule


