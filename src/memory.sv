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

    localparam MEM_SIZE = 2048;
    reg [31:0] memory [0:MEM_SIZE-1];

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        READ = 2'b01,
        WRITE = 2'b10
    } state_t;

    state_t imem_state, dmem_state;
    integer imem_cycle_count, dmem_cycle_count;

    reg [29:0] i_addr;
    reg [29:0] d_addr;

    initial begin
        for (int i = 0; i < MEM_SIZE; i++) begin
            memory[i] = 32'b0;
        end
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
                        imem_state <= READ;
                    end
                    else if (in_imem_write_en) begin
                        imem_state <= WRITE;
                    end
                end

                READ: begin
                    imem_cycle_count <= imem_cycle_count + 1;
                    if (imem_cycle_count == 9) begin
                        i_addr = in_imem_addr[31:2];
                        out_imem_read_data <= {
                            memory[i_addr+3],
                            memory[i_addr+2],
                            memory[i_addr+1],
                            memory[i_addr]
                        };
                        out_imem_ready <= 1;
                        imem_state <= IDLE;
                    end
                end

                WRITE: begin
                    imem_cycle_count <= imem_cycle_count + 1;
                    if (imem_cycle_count == 9) begin
                        memory[in_imem_addr >> 2]       <= in_imem_write_data[31:0];
                        memory[in_imem_addr >> 2 + 1]   <= in_imem_write_data[63:32];
                        memory[in_imem_addr >> 2 + 2]   <= in_imem_write_data[95:64];
                        memory[in_imem_addr >> 2 + 3]   <= in_imem_write_data[127:96];
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
                        d_addr = in_dmem_addr[31:2];
                        out_dmem_read_data <= {
                            memory[d_addr+3],
                            memory[d_addr+2],
                            memory[d_addr+1],
                            memory[d_addr]
                        };
                        out_dmem_ready <= 1;
                        dmem_state <= IDLE;
                    end
                end

                WRITE: begin
                    dmem_cycle_count <= dmem_cycle_count + 1;
                    if (dmem_cycle_count == 9) begin
                        memory[in_dmem_addr >> 2]       <= in_dmem_write_data[31:0];
                        memory[in_dmem_addr >> 2 + 1]   <= in_dmem_write_data[63:32];
                        memory[in_dmem_addr >> 2 + 2]   <= in_dmem_write_data[95:64];
                        memory[in_dmem_addr >> 2 + 3]   <= in_dmem_write_data[127:96];
                        out_dmem_ready <= 1;
                        dmem_state <= IDLE;
                    end
                end

                default: dmem_state <= IDLE;
            endcase
        end
    end

endmodule