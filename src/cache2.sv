module cache #(
    parameter CACHE_LINE_SIZE = 128,
    parameter NUM_SETS = 2,             //2-way set associative 
    parameter NUM_WAYS = 2
    )(
    input wire clk,
    input wire reset,

    //INPUT
    input wire [31:0] in_addr,
    input wire [31:0] in_write_data,
    input wire in_write_en,
    input wire in_read_en,
    input wire [2:0] in_funct3,               //Distinguish B, H, W. Addresses are supposed to be input correctly for different types

    //MEM IFACE
    input wire [CACHE_LINE_SIZE-1:0] in_mem_read_data,
    input wire in_mem_ready,

    //OUTPUT
    output reg [31:0] out_read_data,
    output reg out_busy,                //Stall the pipeline
    output reg out_hit,

    //MEM IFACE
    output reg out_mem_read_en,
    output reg out_mem_write_en,
    output reg [31:0] out_mem_addr,
    output reg [CACHE_LINE_SIZE-1:0] out_mem_write_data

);
    //funct3
    localparam LB = 3'b000;
    localparam LH = 3'b001;
    localparam LW = 3'b010;

    localparam SB = 3'b100;
    localparam SH = 3'b101;
    localparam SW = 3'b110;

    reg [CACHE_LINE_SIZE-1:0] data [NUM_SETS-1:0][NUM_WAYS-1:0];
    reg [19:0] tags [NUM_SETS-1:0][NUM_WAYS-1:0];  
    reg valid [NUM_SETS-1:0][NUM_WAYS-1:0];        
    reg dirty [NUM_SETS-1:0][NUM_WAYS-1:0];
    reg [NUM_WAYS-1:0] lru [NUM_SETS-1:0];         

    /*
    31                              4 3 2 1 0
    +------------------------------+-+-+-+-+-+
    |              TAG             |S|W|W|B|B|
    +------------------------------+-+-+-+-+-+
                                    | +--+ +-+
                                    |    |  |
                                    |    |  +-- Byte offset (2 bits: 00-11)
                                    |    +---- Word offset (2 bits: 00-11)
                                    +-------- Set index (1 bit: 0-1)
    */
    wire [26:0] tag = in_addr[31:5];
    wire set_index = in_addr[4:4];            
    wire [1:0] word_offset = in_addr[3:2];
    wire [1:0] byte_offset = in_addr[1:0];
    
    //Pending read/write
    reg pending_store;
    reg [31:0] pending_store_data;
    reg [2:0] pending_funct3;

    //State machine
    localparam IDLE = 2'b00;
    localparam MEM_READ = 2'b01;
    localparam MEM_WRITE = 2'b10;
    reg [1:0] state;
    reg [31:0] word_data;
    integer way_to_replace;


    always @(posedge clk) begin
        if (reset) begin    
            for(int i = 0; i < NUM_SETS; i++) begin
                for(int j = 0; j < NUM_WAYS; j++) begin
                    valid[i][j] <= 0;
                    tags[i][j] <= 0;
                    dirty[i][j] <= 0;
                    lru[i] <= 0;
                    out_mem_read_en <= 0;
                    out_mem_write_en <= 0;
                end
            end
            state <= IDLE;
            out_busy <= 0;
            out_hit <= 0;
        end else begin
            case(state)
                IDLE: begin
                    out_hit <= 0;
                    out_busy <= 0;
                    out_mem_read_en <= 0;
                    out_mem_write_en <= 0;
                    if (in_read_en || in_write_en) begin
                        for (int i = 0; i < NUM_WAYS; i++) begin //Comparators for all the ways in the set
                            if (valid[set_index][i] && tags[set_index][i] == tag) begin
                                out_hit <= 1;
                                lru[set_index] <= i ? 2'b10 : 2'b01; //We set the opposite of the one we just hit
                                out_mem_read_en <= 0;
                                out_mem_write_en <= 0;

                                if (in_read_en) begin
                                    word_data = data[set_index][i][word_offset*32 +: 32];
                                    case (in_funct3)
                                        LB: out_read_data <= sign_extend(word_data[byte_offset*8 +: 8], in_funct3);
                                        LH: out_read_data <= sign_extend(word_data[byte_offset*16 +: 16], in_funct3);
                                        LW: out_read_data <= word_data;
                                    endcase
                                end
                                if (in_write_en) begin
                                    word_data <= data[set_index][i][word_offset*32 +: 32];
                                    case (in_funct3)
                                        SB: word_data[byte_offset*8 +: 8] <= in_write_data[7:0];
                                        SH: word_data[byte_offset*16 +: 16] <= in_write_data[15:0];
                                        SW: word_data <= in_write_data;
                                    endcase 
                                    data[set_index][i][word_offset*32 +: 32] <= word_data;
                                    dirty[set_index][i] <= 1;
                                end
                            end
                        end
                        if (!out_hit) begin
                            way_to_replace <= lru[set_index] == 2'b10 ? 0 : 1;
                            out_busy <= 1;

                            if (in_write_en) begin
                                pending_store <= 1;
                                pending_store_data <= in_write_data;
                                pending_funct3 <= in_funct3;
                            end

                            if (valid[set_index][way_to_replace] && dirty[set_index][way_to_replace]) begin //If dirty, we have to write to memory
                                state <= MEM_WRITE;
                            end else begin
                                out_mem_addr <= {tag, set_index, 4'b0000};
                                out_mem_read_en <= 1;
                                state <= MEM_READ;
                            end
                        end
                    end
                end
                MEM_WRITE: begin
                    //Initiate petition to write to memory
                    out_mem_addr <= {tags[set_index][way_to_replace], set_index, 4'b0000};
                    out_mem_write_data <= data[set_index][way_to_replace];
                    out_mem_write_en <= 1;
                    if (in_mem_ready) begin
                        out_mem_write_en <= 0;
                        dirty[set_index][way_to_replace] <= 0;

                        out_mem_addr <= {tag, set_index, 4'b0000};
                        out_mem_read_en <= 1;
                        state <= MEM_READ;
                    end
                end
                MEM_READ: begin
                    if (in_mem_ready) begin
                        out_mem_read_en <= 0;
                        way_to_replace <= lru[set_index] == 2'b10 ? 0 : 1;

                        data[set_index][way_to_replace] <= in_mem_read_data;

                        if (pending_store) begin
                            word_data = in_mem_read_data[word_offset*32 +: 32];
                            case (pending_funct3)
                                SB: word_data[byte_offset*8 +: 8] <= pending_store_data[7:0];
                                SH: word_data[byte_offset*16 +: 16] <= pending_store_data[15:0];
                                SW: word_data <= pending_store_data;
                            endcase
                            data[set_index][way_to_replace][word_offset*32 +: 32] <= word_data;
                            dirty[set_index][way_to_replace] <= 1;
                        end else if (in_read_en) begin
                            out_read_data <= data[set_index][way_to_replace];
                        end
                        valid[set_index][way_to_replace] <= 1;
                        tags[set_index][way_to_replace] <= tag;
                        
                        out_busy <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    function automatic [31:0] sign_extend;
        input [31:0] data;
        input [2:0] size;  // 0=byte, 1=halfword, 2=word
        begin
            case(size)
                0: sign_extend = {{24{data[7]}}, data[7:0]};
                1: sign_extend = {{16{data[15]}}, data[15:0]};
                default: sign_extend = data;
            endcase
        end
    endfunction
endmodule;
