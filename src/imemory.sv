module imemory (
    input clk,
    input [31:0] mem_addr,
    output [31:0] inst_out
);

    reg [31:0] ROM [0:1023];


    assign inst_out = ROM[mem_addr];

endmodule
