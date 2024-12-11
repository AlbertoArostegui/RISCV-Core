module reorder_buffer #(
    parameter ROB_SIZE = 10
    ) (
    input  wire         clk,
    input  wire         reset,
    
    //INPUT
    //From decode
    input  wire         in_allocate,
    input  wire [31:0]  in_PC,
    input  wire [31:0]  in_addr_miss,
    input  wire [31:0]  in_value,
    input  wire [4:0]   in_rd,
    input  wire [2:0]   in_inst_type,

    //From execute
    input  wire         in_complete,
    input  wire [3:0]   in_complete_idx,
    input  wire [31:0]  in_complete_value,
    input  wire [2:0]   in_exception,
    
    //OUTPUT
    output reg          out_ready,
    output reg  [31:0]  out_value,
    output reg  [31:0]  out_miss_addr,
    output reg  [31:0]  out_PC,
    output reg  [4:0]   out_rd,
    output reg  [2:0]   out_exception,
    
    output wire         out_full,
    output wire [3:0]   out_alloc_idx
);

reg [3:0] head;
reg [3:0] tail;
reg [3:0] count;

typedef struct packed {
    reg [31:0]  PC;
    reg [31:0] addr_miss;
    reg [31:0]  value;
    reg [4:0]   rd;
    reg         valid;
    reg         complete;
    reg [2:0]   exception;
} rob_entry;

rob_entry [ROB_SIZE-1:0] entries;

assign out_full = (count == ROB_SIZE);
assign out_alloc_idx = tail;

always @(posedge clk) begin
    if (reset) begin
        head <= 0;
        tail <= 0;
        count <= 0;
        out_ready <= 0;
        
        for (int i = 0; i < ROB_SIZE; i++) begin
            entries[i].valid <= 0;
            entries[i].complete <= 0;
        end
    end
    else begin
        // Allocation
        if (in_allocate && !out_full) begin
            entries[tail].PC <= in_PC;
            entries[tail].addr_miss <= in_addr_miss;
            entries[tail].value <= in_value;
            entries[tail].rd <= in_rd;
            entries[tail].valid <= 1;
            entries[tail].complete <= 0;
            entries[tail].exception <= 0;
            
            tail <= (tail + 1) % ROB_SIZE;
            count <= count + 1;
        end
        
        // Completion
        if (in_complete) begin
            entries[in_complete_idx].value <= in_complete_value;
            entries[in_complete_idx].complete <= 1;
            entries[in_complete_idx].exception <= in_exception;
        end
        
        // Commit
        if (entries[head].valid && entries[head].complete) begin
            out_ready <= 1;
            out_value <= entries[head].value;
            out_miss_addr <= entries[head].addr_miss;
            out_PC <= entries[head].PC;
            out_rd <= entries[head].rd;
            out_exception <= entries[head].exception;

            entries[head].valid <= 0;
            head <= (head + 1) % ROB_SIZE;
            count <= count - 1;
        end
        else begin
            out_ready <= 0;
        end
    end
end

endmodule
