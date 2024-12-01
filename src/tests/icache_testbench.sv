
module icache_tb;

    // Parameters
    parameter CACHE_SIZE = 128;
    parameter LINE_SIZE = 4;
    parameter WORD_SIZE = 32;

    // Signals
    reg clk;
    reg reset;
    reg [31:0] addr;
    reg valid;
    reg [WORD_SIZE-1:0] mem_data;
    wire hit;
    wire [WORD_SIZE-1:0] data;
    wire mem_read;
    wire [31:0] mem_addr;

    // Instantiate the icache module
    icache #(
        .CACHE_SIZE(CACHE_SIZE),
        .LINE_SIZE(LINE_SIZE),
        .WORD_SIZE(WORD_SIZE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .valid(valid),
        .mem_data(mem_data),
        .hit(hit),
        .data(data),
        .mem_read(mem_read),
        .mem_addr(mem_addr)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        addr = 0;
        valid = 0;
        mem_data = 0;

        // Reset the cache
        #10 reset = 0;

        // Test case 1: Cache miss and load from memory
        addr = 32'h00000010;
        valid = 1;
        mem_data = 32'hDEADBEEF;
        #10;
        valid = 0;
        #10;

        // Test case 2: Cache hit
        addr = 32'h00000010;
        valid = 1;
        #10;
        valid = 0;
        #10;

        // Test case 3: Another cache miss
        addr = 32'h00000020;
        valid = 1;
        mem_data = 32'hCAFEBABE;
        #10;
        valid = 0;
        #10;

        // Test case 4: Cache hit
        addr = 32'h00000020;
        valid = 1;
        #10;
        valid = 0;
        #10;

        // Finish simulation
        $finish;
    end

endmodule