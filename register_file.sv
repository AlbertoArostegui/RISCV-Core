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
    output reg [31:0] r0,
    output reg [31:0] r1,
    output reg [31:0] r2,
    output reg [31:0] r3,
    output reg [31:0] r4,
    output reg [31:0] r5,
    output reg [31:0] r6,
    output reg [31:0] r7,
    output reg [31:0] r8
);

wire [31:0] out_data;

reg [31:0] registers [0:31];

initial begin
    for (integer i=0; i <32; i++) 
        registers[i] = 0;
    registers[2] = 32'd10;
    registers[3] = 32'd20;
    registers[5] = 32'd30;
    registers[6] = 32'd15;
end

always @(*) begin
    out_data_a <= registers[reg_a];
    out_data_b <= registers[reg_b];
end

always @(posedge clk) begin
    if (we && wreg != 0) begin
        registers[wreg] = wdata;
    end
    r0 <= registers[0];
    r1 <= registers[1];
    r2 <= registers[2];
    r3 <= registers[3];
    r4 <= registers[4];
    r5 <= registers[5];
    r6 <= registers[6];
    r7 <= registers[7];
    r8 <= registers[8];
end
endmodule


