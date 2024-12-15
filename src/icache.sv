module icache #(
    parameter CACHE_SIZE = 128,          // Total size of the cache
    parameter LINE_SIZE = 4,             // Number of words per cache line
    parameter WORD_SIZE = 32             // Size of each word in bits
)(
    input clk,                            // Clock signal
    input reset,                          // Reset signal
    input [31:0] addr,                    // Address from CPU
    input valid,                          // Signal indicating a valid address
    input [WORD_SIZE-1:0] mem_data,       // Data from memory
    output reg hit,                       // Hit flag
    output reg [WORD_SIZE-1:0] data,      // Data output on a hit
    output reg mem_read,                  // Memory read signal
    output reg [31:0] mem_addr,            // Address to read from memory
    output reg ready                      // Signal indicating cache is ready
);

// Cache data and tag arrays
reg [WORD_SIZE-1:0] cache_data[CACHE_SIZE-1:0];   // Store cache data
reg [31:0] cache_tag[CACHE_SIZE/LINE_SIZE-1:0];   // Store cache tags
reg cache_valid[CACHE_SIZE/LINE_SIZE-1:0];        // Valid bits for each cache line

wire [31:0] tag = addr[31:8];                    // Extract tag from address
wire [7:0] index = addr[7:2];                    // Extract index (assuming 4-byte words)


always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Initialize cache by clearing valid bits
        integer i;
        for (i = 0; i < CACHE_SIZE / LINE_SIZE; i = i + 1) begin
            cache_valid[i] <= 0;
        end
        hit <= 0;
        ready <= 0;
    end else if (valid) begin
        // Check for cache hit
        if (cache_valid[index] && cache_tag[index] == tag) begin
            hit <= 1;                             
            data <= cache_data[index];            
            ready <= 1;
        end else begin
            hit <= 0;                             
            mem_read <= 1;                        
            mem_addr <= addr;                     
            
            cache_data[index] <= mem_data;
            cache_tag[index] <= tag;
            cache_valid[index] <= 1;
            ready <= 0;
        end
    end
end

endmodule