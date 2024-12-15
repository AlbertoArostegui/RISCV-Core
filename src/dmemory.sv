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

    always @(*) begin
        out_data <= MEMORY[in_mem_addr[9:0]];
    end

    always @(posedge clk) begin
        if (reset) begin
            for (integer i = 0; i < MAXMEM; i++) begin
                MEMORY[i] <= 0;
            end
        end
        if (in_mem_write) begin
            MEMORY[in_mem_addr[9:0]] <= in_mem_data;
        end
    end

endmodule
