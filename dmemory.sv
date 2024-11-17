module dmemory (
    input clk,
    input reset,

    //INPUT
    input [31:0] in_mem_addr,
    input [31:0] in_mem_data,
    input in_mem_write,
    input in_mem_read,

    //OUTPUT
    output reg [31:0] out_data
);

    localparam MAXMEM = 1024;
    reg [31:0] MEMORY [0:MAXMEM - 1];

    always @(*)
        out_data <= ROM[in_mem_addr[9:0]];

    always @(posedge clk) begin
        if (reset)
            for (integer i = 0; i < MAXMEM; i++)
                MEMORY[i] = 0;
        if (in_mem_write) begin
            MEMORY[in_mem_addr] <= in_mem_data;
        end
    end

endmodule
