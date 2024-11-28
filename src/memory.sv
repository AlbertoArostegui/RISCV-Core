module memory_module (
    input wire clk,
    input wire reset,

    //INPUT
    input wire in_mem_read_en,
    input wire in_mem_write_en,
    input wire [31:0] in_mem_addr,
    input wire [127:0] in_mem_write_data,

    //OUTPUT
    output reg [127:0] out_mem_read_data,
    output reg out_mem_ready
);

    // Define memory size (e.g., 1024 lines of 128 bits)
    localparam MEM_SIZE = 1024;
    reg [7:0] memory [0:MEM_SIZE*16-1]; // 128 bits = 16 bytes

    // State machine for memory operations
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        READ = 2'b01,
        WRITE = 2'b10
    } state_t;

    state_t state;
    integer cycle_count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            cycle_count <= 0;
            out_mem_ready <= 0;
            out_mem_read_data <= 128'b0;
            // Initialize memory if needed
            for (integer i = 0; i < MEM_SIZE*16; i++) begin
                memory[i] <= 8'h00;
            end
        end
        else begin
            case (state)
                IDLE: begin
                    out_mem_ready <= 0;
                    if (in_mem_read_en) begin
                        state <= READ;
                        cycle_count <= 0;
                    end
                    else if (in_mem_write_en) begin
                        state <= WRITE;
                        cycle_count <= 0;
                    end
                end

                READ: begin
                    cycle_count <= cycle_count + 1;
                    if (cycle_count == 10) begin
                        // Assemble 128-bit read data from memory
                        out_mem_read_data <= {
                            memory[in_mem_addr + 15],
                            memory[in_mem_addr + 14],
                            memory[in_mem_addr + 13],
                            memory[in_mem_addr + 12],
                            memory[in_mem_addr + 11],
                            memory[in_mem_addr + 10],
                            memory[in_mem_addr + 9],
                            memory[in_mem_addr + 8],
                            memory[in_mem_addr + 7],
                            memory[in_mem_addr + 6],
                            memory[in_mem_addr + 5],
                            memory[in_mem_addr + 4],
                            memory[in_mem_addr + 3],
                            memory[in_mem_addr + 2],
                            memory[in_mem_addr + 1],
                            memory[in_mem_addr]
                        };
                        out_mem_ready <= 1;
                        state <= IDLE;
                    end
                end

                WRITE: begin
                    cycle_count <= cycle_count + 1;
                    if (cycle_count == 10) begin
                        // Write 128-bit data to memory
                        for (integer i = 0; i < 16; i++) begin
                            memory[in_mem_addr + i] <= in_mem_write_data[i*8 +: 8];
                        end
                        out_mem_ready <= 1;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule