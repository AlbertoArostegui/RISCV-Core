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

    localparam SB = 3'b000;
    localparam SH = 3'b001;
    localparam SW = 3'b010;

    reg [CACHE_LINE_SIZE-1:0] data [NUM_SETS-1:0][NUM_WAYS-1:0];
    reg [19:0] tags [NUM_SETS-1:0][NUM_WAYS-1:0];  
    reg valid [NUM_SETS-1:0][NUM_WAYS-1:0];        
    reg dirty [NUM_SETS-1:0][NUM_WAYS-1:0];
    reg [NUM_WAYS-1:0] lru;         

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

    reg [CACHE_LINE_SIZE-1:0] cache_line;

    // Combinational hit detection and data read/write
    always @(*) begin
        // Default values
        out_busy = 0;
        out_hit = 0;
        out_read_data = 32'b0;
        
        if (in_read_en || in_write_en) begin
            // Check all ways in parallel
            for (int i = 0; i < NUM_WAYS; i++) begin
                if (valid[set_index][i] && tags[set_index][i] == tag) begin
                    out_hit = 1;
                    if (in_read_en) begin
                        word_data = data[set_index][i][word_offset*32 +: 32];
                        case (in_funct3)
                            LB: out_read_data = sign_extend(word_data[byte_offset*8 +: 8], in_funct3);
                            LH: out_read_data = sign_extend(word_data[byte_offset*16 +: 16], in_funct3);
                            LW: out_read_data = word_data;
                        endcase
                    end
                end
            end
            if (!out_hit) out_busy = 1;
            if (in_mem_ready) out_mem_read_en = 0;
        end
    end

    // Sequential block only handles misses and state transitions
    always @(posedge clk) begin
        //display_cache_state(); //This displays the cache state each cycle
        if (reset) begin
            for(int i = 0; i < NUM_SETS; i++) begin
                for(int j = 0; j < NUM_WAYS; j++) begin
                    valid[i][j] <= 0;
                    tags[i][j] <= 0;
                    dirty[i][j] <= 0;
                    out_mem_read_en <= 0;
                    out_mem_write_en <= 0;
                end
                lru[i] <= 0;
            end
            state <= IDLE;
            out_busy <= 0;
            out_hit <= 0;
        end else begin
            case (state)
                IDLE: begin
                    out_mem_read_en <= 0;
                    out_mem_write_en <= 0;
                    
                    if ((in_read_en || in_write_en) && !out_hit) begin
                        way_to_replace = lru[set_index];

                        if (in_write_en) begin
                            pending_store <= 1;
                            pending_store_data <= in_write_data;
                            pending_funct3 <= in_funct3;
                        end

                        if (valid[set_index][way_to_replace] && dirty[set_index][way_to_replace]) begin
                            state <= MEM_WRITE;
                        end else begin
                            out_mem_addr <= {tag, set_index, 4'b0000};
                            out_mem_read_en <= 1;
                            state <= MEM_READ;
                        end
                    end
                    $display("in_write_en: %b, out_hit: %b", in_write_en, out_hit);
                    if (in_write_en && out_hit) begin
                        for (int i = 0; i < NUM_WAYS; i++) begin
                            if (valid[set_index][i] && tags[set_index][i] == tag) begin
                                case (in_funct3)
                                    SB: begin
                                        data[set_index][i][(word_offset*32) + (byte_offset*8) +: 8] <= in_write_data[7:0];
                                    end
                                    SH: begin
                                        data[set_index][i][(word_offset*32) + (byte_offset*16) +: 16] <= in_write_data[15:0];
                                    end
                                    SW: begin
                                        data[set_index][i][word_offset*32 +: 32] <= in_write_data;
                                    end
                                endcase
                                dirty[set_index][i] <= 1;
                                lru[set_index] <= ~i;
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
                        lru[set_index] <= ~way_to_replace;
                        
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
    task automatic display_cache_state;
    string line = "┌────────┬────────────┬──────────────────────────────────┬───────┬───────┐";
    string header = "│ Set/Way│    Tag     │               Data               │ Valid │ Dirty │";
    
    $display("\n%c[1;36m==== Cache State Display ====%c[0m", 27, 27);
    $display(line);
    $display(header);
    $display(line);
    
    for(int i = 0; i < NUM_SETS; i++) begin
        for(int j = 0; j < NUM_WAYS; j++) begin
            $display("│ %1d/%1d    │ %07h    │ %032h │   %b   │   %b   │", 
                    i, j, 
                    tags[i][j], 
                    data[i][j], 
                    valid[i][j], 
                    dirty[i][j]);
        end
        if (i != NUM_SETS-1) $display("├────────┼────────────┼──────────────────────────────────┼───────┼───────┤");
    end
    $display("└────────┴────────────┴──────────────────────────────────┴───────┴───────┘");
    $display("LRU States: Set0=%0d, Set1=%0d\n", lru[0], lru[1]);
    endtask
endmodule
