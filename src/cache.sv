module cache #(
    parameter CACHE_LINE_SIZE = 128,    
    parameter NUM_SETS = 2,             // 2-way set associative
    parameter NUM_WAYS = 2              
)(
    input wire clk,
    input wire reset,

    //INPUT
    input wire [31:0] in_addr,
    input wire [31:0] in_write_data,      
    input wire in_write_en,               
    input wire in_read_en,                 
    input wire [2:0] in_funct3,

    //MEMORY INTERFACE
    input wire [127:0] mem_read_data,
    
    //OUTPUT
    output reg [31:0] out_read_data,       
    output reg out_hit,                    
    output reg out_busy                    

    //MEMORY INTERFACE
    output reg mem_read_en,
    output reg mem_write_en,
    output reg [31:0] mem_addr,
    output reg [127:0] mem_write_data
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

    reg [4:0] mem_access_counter;
    reg mem_access_in_progress;

    /*
    31                  12 11     5 4 3 2 1 0
    +---------------------+--------+-+-+-+-+-+
    |        TAG          | UNUSED |S|W|W|B|B|
    +---------------------+--------+-+-+-+-+-+
                                    | +--+ +-+
                                    |    |  |
                                    |    |  +-- Byte offset (2 bits: 00-11)
                                    |    +---- Word offset (2 bits: 00-11)
                                    +-------- Set index (1 bit: 0-1)
    */
    wire [19:0] tag = in_addr[31:12];
    wire set_index = in_addr[4:4];            
    wire [1:0] word_offset = in_addr[3:2];
    wire [1:0] byte_offset = in_addr[1:0];
    
    //Pending read/write
    reg pending_write;
    reg [31:0] pending_write_data;
    reg [2:0] pending_funct3;

    //State machine
    localparam IDLE = 2'b00;
    localparam MEM_READ = 2'b01;
    localparam MEM_WRITE = 2'b10;
    reg [1:0] state;

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

    always @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < NUM_SETS; i++) begin
                for (int j = 0; j < NUM_WAYS; j++) begin
                    valid[i][j] <= 0;
                    tags[i][j] <= 0;
                    dirty[i][j] <= 0;
                    lru[i] <= 0;
                    mem_read_en <= 0;
                    mem_write_en <= 0;
                end
            end
            state <= IDLE;
            out_busy <= 0;
            mem_access_counter <= 0;
            mem_access_in_progress <= 0;
        end else begin
            case (state)
                IDLE: begin
                    out_hit <= 0;
                    if (in_read_en || in_write_en) begin
                        for (int i = 0; i < NUM_WAYS; i++) begin
                            //You compare with all the different ways in the
                            //set (The different comparators)
                            if (valid[set_index][i] && tags[set_index][i] == tag) begin //On a hit
                                out_hit <= 1;
                                lru[set_index] <= i ? 2'b01 : 2'b10;
                                mem_read_en <= 0;
                                mem_write_en <= 0;

                                if (in_read_en) begin
                                    reg [31:0] word_data;
                                    //Word in line
                                    word_data = data[set_index][i][word_offset*32 +: 32];
                                    case (in_funct3)
                                        LB: read_data = sign_extend(word_data[byte_offset*8 +: 8], in_funct3);
                                        LH: read_data = sign_extend(word_data[byte_offset*16 +: 16], in_funct3);
                                        LW: read_data = word_data;
                                    endcase
                                end else if (in_write_en) begin
                                    /*We assume when storing with SB and SH that we only want
                                    to overwrite the byte or halfword and leave the rest of the word unchanged*/

                                    reg [31:0] word_data = data[set_index][i][word_offset*32 +: 32];
                                    case (in_funct3)
                                        SB: word_data[byte_offset*8 +: 8] = in_write_data[7:0];
                                        SH: word_data[byte_offset*16 +: 16] = in_write_data[15:0];
                                        SW: word_data = in_write_data;
                                    endcase
                                    data[set_index][i][word_offset*32 +: 32] <= word_data;
                                    dirty[set_index][i] <= 1;
                                end
                            end
                        end
                        
                        if (!out_hit) begin //On a miss, whatever mode
                            out_busy <= 1;

                            pending_write <= in_write_en;
                            pending_write_data <= in_write_data;
                            pending_funct3 <= in_funct3;

                            integer way_to_replace = lru[set_index][0] ? 0 : 1;
                            /*If we are going to evict a line, we should check if 
                            it is dirty and write it back to memory if so*/
                            if (valid[set_index][way_to_replace] && dirty[set_index][way_to_replace]) begin
                                state <= MEM_WRITE;
                            end else begin
                                state <= MEM_READ;
                            end

                            mem_access_counter <= 5'd0;
                        end
                    end
                end

                MEM_WRITE: begin
                    // Write back dirty line (10 cycles)
                    if (mem_access_counter == 5'd5) begin
                        int way_to_replace = lru[set_index][0] ? 0 : 1;
                        mem_addr <= {tags[set_index][way_to_replace], set_index, 2'b00};
                        mem_write_data <= data[set_index][way_to_replace];
                        mem_write_en <= 1;
                    end
                    if (mem_access_counter == 5'd10) begin
                        mem_write_en <= 0;
                        int way_to_replace = lru[set_index][0] ? 0 : 1;

                        // Clear dirty bit as line is now clean
                        dirty[set_index][way_to_replace] <= 0;
                        // Now go fetch the new line
                        state <= MEM_READ;
                        mem_access_counter <= 5'd0;
                    end else begin
                        mem_access_counter <= mem_access_counter + 1;
                    end
                end

                MEM_READ: begin
                    //We start at 0, so we need to wait for 10 cycles
                    if (mem_access_counter == 5'd5) begin
                        mem_addr <= {tag, set_index, 2'b00};
                    end
                    if (mem_access_counter == 5'd10) begin  
                        int way_to_replace = lru[set_index][0] ? 0 : 1;
                        
                        if (pending_write) begin
                            reg [31:0] word_data = data[set_index][way_to_replace][word_offset*32 +: 32];
                            case (pending_funct3)
                                SB: word_data[byte_offset*8 +: 8] = pending_write_data[7:0];
                                SH: word_data[byte_offset*16 +: 16] = pending_write_data[15:0];
                                SW: word_data = pending_write_data;
                            endcase
                            data[set_index][way_to_replace][word_offset*32 +: 32] <= word_data;
                            dirty[set_index][way_to_replace] <= 1;
                        end

                        valid[set_index][way_to_replace] <= 1;
                        tags[set_index][way_to_replace] <= tag;
                       
                        state <= IDLE;
                        out_busy <= 0;
                    end else begin
                        mem_access_counter <= mem_access_counter + 1;
                    end
                end
            endcase
        end
    end
endmodule
