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

    localparam MEM_SIZE = 16384; //words, so 4MiB
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
            memory[i] = 32'h00000013;
        end
        /*
        Boot sequence. We boot in supervisor mode at PC = 0x1000 (0x400 in memory), 
        point to a direction to the program start PC = 0x80 and then we exec sret.
        */
        memory[32'h400] = 32'h05000093; //addi x1, x0, 80 
        memory[32'h401] = 32'h00009073; //movrm rm0, x1 (In reality, this is csrrw x0, ustatus, x1. We will use it as mov into rm0 the value from x1)
        memory[32'h402] = 32'h10200073; //sret (iret)

        /*
        Service exceptions. We jump to PC = 0x2000 (0x800 in memory),
        which is the exception handler. We service the exceptions according to the exception vector.
        Current design only services TLBMiss.
        */

        //Code for iTLBMiss
        memory[32'h800] = 32'h00502423; //sw x5, 8(x0)
        memory[32'h801] = 32'h00602623; //sw x6, 12(x0)
        memory[32'h802] = 32'h800002b3; //movrm x5, rm1 //This is really add x1, x0, x0, but with a special funct7 to take rm1
        memory[32'h803] = 32'h7d000393; //addi x7, x0, 2000

        memory[32'h804] = 32'h7d038393; //addi x7, x7, 2000
        memory[32'h805] = 32'h7d038393; //addi x7, x7, 2000
        memory[32'h806] = 32'h7d038393; //addi x7, x7, 2000
        memory[32'h807] = 32'h00728333; //add x6, x5, x7 //So x6 = VA (in x5) + 8000

        memory[32'h808] = 32'h00628008; //itlbwrite x5, x6 //dtlb would be with funct3 = 001
        memory[32'h809] = 32'h00802283; //lw x5, 8(x0)
        memory[32'h80a] = 32'h00c02303; //lw x6, 12(x0)
        memory[32'h80b] = 32'h10200073; //sret (iret)

        //Code for dTLBMiss
        memory[32'h880] = 32'h00502423; //sw x5, 8(x0)
        memory[32'h881] = 32'h00602623; //sw x6, 12(x0)
        memory[32'h882] = 32'h800002b3; //movrm x5, rm1 //This is really add x1, x0, x0, but with a special funct7 to take rm1
        memory[32'h883] = 32'h7d000393; //addi x7, x0, 2000

        memory[32'h884] = 32'h7d038393; //addi x7, x7, 2000
        memory[32'h885] = 32'h7d038393; //addi x7, x7, 2000
        memory[32'h886] = 32'h7d038393; //addi x7, x7, 2000
        memory[32'h887] = 32'h00728333; //add x6, x5, x7 //So x6 = VA (in x5) + 8000

        memory[32'h888] = 32'h00629008; //dtlbwrite x5, x6, funct3 = 001
        memory[32'h889] = 32'h00802283; //lw x5, 8(x0)
        memory[32'h88a] = 32'h00c02303; //lw x6, 12(x0)
        memory[32'h88b] = 32'h10200073; //sret (iret)
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