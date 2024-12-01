module memory (
    input wire clk,
    input wire reset,

    //INPUT
    input wire in_imem_read_en,
    input wire in_imem_write_en,
    input wire [31:0] in_imem_addr,
    input wire [127:0] in_imem_write_data,

    input wire in_dmem_read_en,
    input wire in_dmem_write_en,
    input wire [31:0] in_dmem_addr,
    input wire [127:0] in_dmem_write_data,

    //OUTPUT
    output reg [127:0] out_imem_read_data,
    output reg out_imem_ready,

    output reg [127:0] out_dmem_read_data,
    output reg out_dmem_ready
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

    state_t imem_state, dmem_state;
    integer imem_cycle_count, dmem_cycle_count;
    bit initialized = 0;

    initial begin
        for (integer i = 0; i < MEM_SIZE*16; i++) begin
            memory[i] = i & 8'hFF;  // Each byte is its own index (modulo 256)
        end

        initialized = 1;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            imem_state <= IDLE;
            dmem_state <= IDLE;
            imem_cycle_count <= 0;
            dmem_cycle_count <= 0;
            out_imem_ready <= 0;
            out_imem_read_data <= 128'b0;
            out_dmem_ready <= 0;
            out_dmem_read_data <= 128'b0;
        end
        else begin
            case (imem_state)
                IDLE: begin
                    out_imem_ready <= 0;
                    imem_cycle_count <= 0;   
                    if (in_imem_read_en) begin
                        state <= READ;
                    end
                    else if (in_imem_write_en) begin
                        imem_state <= WRITE;
                    end
                end

                READ: begin
                    imem_cycle_count <= imem_cycle_count + 1;
                    if (imem_cycle_count == 9) begin
                        // Assemble 128-bit read data from memory
                        out_imem_read_data <= {
                            memory[in_imem_addr + 15],
                            memory[in_imem_addr + 14],
                            memory[in_imem_addr + 13],
                            memory[in_imem_addr + 12],
                            memory[in_imem_addr + 11],
                            memory[in_imem_addr + 10],
                            memory[in_imem_addr + 9],
                            memory[in_imem_addr + 8],
                            memory[in_imem_addr + 7],
                            memory[in_imem_addr + 6],
                            memory[in_imem_addr + 5],
                            memory[in_imem_addr + 4],
                            memory[in_imem_addr + 3],
                            memory[in_imem_addr + 2],
                            memory[in_imem_addr + 1],
                            memory[in_imem_addr]
                        };
                        out_imem_ready <= 1;
                        imem_state <= IDLE;
                    end
                end

                WRITE: begin
                    imem_cycle_count <= imem_cycle_count + 1;
                    if (imem_cycle_count == 9) begin
                        // Write 128-bit data to memory
                        for (integer i = 0; i < 16; i++) begin
                            memory[in_imem_addr + i] <= in_imem_write_data[i*8 +: 8];
                        end
                        out_imem_ready <= 1;
                        imem_state <= IDLE;
                    end
                end

                default: imem_state <= IDLE;
            endcase
            case (dmem_state)
                IDLE: begin
                    out_dmem_ready <= 0;
                    dmem_cycle_count <= 0;   
                    if (in_dmem_read_en) begin
                        dmem_state <= READ;
                    end
                    else if (in_dmem_write_en) begin
                        dmem_state <= WRITE;
                    end
                end

                READ: begin
                    dmem_cycle_count <= dmem_cycle_count + 1;
                    if (dmem_cycle_count == 9) begin
                        // Assemble 128-bit read data from memory
                        out_dmem_read_data <= {
                            memory[in_dmem_addr + 15],
                            memory[in_dmem_addr + 14],
                            memory[in_dmem_addr + 13],
                            memory[in_dmem_addr + 12],
                            memory[in_dmem_addr + 11],
                            memory[in_dmem_addr + 10],
                            memory[in_dmem_addr + 9],
                            memory[in_dmem_addr + 8],
                            memory[in_dmem_addr + 7],
                            memory[in_dmem_addr + 6],
                            memory[in_dmem_addr + 5],
                            memory[in_dmem_addr + 4],
                            memory[in_dmem_addr + 3],
                            memory[in_dmem_addr + 2],
                            memory[in_dmem_addr + 1],
                            memory[in_dmem_addr]
                        };
                        out_dmem_ready <= 1;
                        dmem_state <= IDLE;
                    end
                end

                WRITE: begin
                    dmem_cycle_count <= dmem_cycle_count + 1;
                    if (dmem_cycle_count == 9) begin
                        // Write 128-bit data to memory
                        for (integer i = 0; i < 16; i++) begin
                            memory[in_dmem_addr + i] <= in_dmem_write_data[i*8 +: 8];
                        end
                        out_dmem_ready <= 1;
                        dmem_state <= IDLE;
                    end
                end

                default: dmem_state <= IDLE;
            endcase
        end
    end

endmodule