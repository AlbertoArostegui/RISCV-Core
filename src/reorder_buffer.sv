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
    input  wire [4:0]   in_rd,
    input  wire [2:0]   in_instr_type,

    //From execute
    input  wire         in_complete,
    input  wire [3:0]   in_complete_idx,
    input  wire [31:0]  in_complete_value,
    input  wire [2:0]   in_exception,

    //From cache
    input wire [31:0]   in_cache_out,
    input wire [3:0]    in_complete_cache_idx,
    input wire [4:0]    in_cache_rd,

    //Control
    input wire          in_stall,
    
    //OUTPUT
    output reg          out_ready,
    output reg  [31:0]  out_value,
    output reg  [31:0]  out_miss_addr,
    output reg  [31:0]  out_PC,
    output reg  [4:0]   out_rd,
    output reg  [2:0]   out_exception,
    output reg  [2:0]   out_instr_type,
    
    output wire         out_full,
    output wire [3:0]   out_alloc_idx
);

/*We should take decisions according to instr_type. We should have at least
* ALU, STORE/LOAD and MUL*/

typedef struct packed {
    reg [31:0]  PC;                     //Faulting instruction PC
    reg [31:0]  addr_miss;              //TLB Miss
    reg [31:0]  value;                  //Value to be written
    reg [4:0]   rd;                     //Register destination
    reg         valid;                  //Valid entry?
    reg         complete;               //Instruction completed?
    reg [2:0]   exception;              //Exception vector
    reg [2:0]   instr_type;             //Instruction type
} rob_entry;

rob_entry [ROB_SIZE-1:0] entries;

reg [3:0] head;
reg [3:0] tail;
reg [3:0] count;

assign out_full = (count == ROB_SIZE);
assign out_alloc_idx = tail;

always @(*) begin
    //Case we complete an instruction
    if (entries[head].complete && entries[head].valid) begin
        if (entries[head].exception != 3'b0) begin
            exception();
        end else begin
            out_ready <= entries[head].complete;
            out_value <= entries[head].value;
            out_rd <= entries[head].rd;
            out_exception <= entries[head].exception;
            out_instr_type <= entries[head].instr_type;
        end
    end    
end

always @(posedge clk) begin
    if (reset) begin                //Reset or exception --> Nuke the ROB
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
        // Allocation. From decode. Only on non stalled cycles
        if (in_allocate && !out_full && !in_stall) begin
            entries[tail].PC <= in_PC;
            entries[tail].addr_miss <= in_addr_miss;            //TODO: TLB Miss
            entries[tail].rd <= in_rd;
            entries[tail].instr_type <= in_inst_type;
            entries[tail].valid <= 1;
            entries[tail].complete <= 0;
            entries[tail].exception <= 2'b0;
            
            tail <= (tail + 1) % ROB_SIZE;
            count <= count + 1;
        end
        
        // Completion. Even on stalled cycles (for now)
        if (in_complete) begin
            entries[in_complete_idx].value <= in_complete_value;
            entries[in_complete_idx].complete <= 1;
            entries[in_complete_idx].exception <= in_exception;
        end
        
        // Commit
        if (entries[head].valid && entries[head].complete && !entries[head].is_store && !in_stall) begin
            out_ready <= 1;
            out_value <= entries[head].value;
            out_miss_addr <= entries[head].addr_miss;
            out_PC <= entries[head].PC;
            out_rd <= entries[head].rd;
            out_exception <= entries[head].exception;
            out_instr_type <= entries[head].instr_type;

            entries[head].valid <= 0;
            head <= (head + 1) % ROB_SIZE;
            count <= count - 1;
        end else if (entries[head].valid && entries[head].complete && !in_stall) begin
            //write to mem
            //write_to_mem();
            entries[head].valid <= 0;
            head <= (head + 1) % ROB_SIZE;
            count <= count - 1;
        end else begin
            out_ready <= 0;
        end
    end
end

task automatic exception;                                                    //This should only be fired on an exception
    if (entries[head].valid && entries[head].exception) begin
        out_PC <= entries[head].PC;
        out_miss_addr <= entries[head].addr_miss;
        head <= 0;
        tail <= 0;
        count <= 0;
        for (int i = 0; i < ROB_SIZE; i++) begin
            entries[i].valid <= 0;
        end

        if (idx == tail && entries[tail].valid)
            entries[tail].valid = 0;
    end
endtask

endmodule
