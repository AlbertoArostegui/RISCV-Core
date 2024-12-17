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

    //From cache (LOADS)
    input wire [31:0]   in_cache_out,
    input wire [3:0]    in_complete_cache_idx,
    input wire [4:0]    in_cache_rd,
    input wire [2:0]    in_cache_exception,

    //From mul
    input wire          in_complete_mul,
    input wire [3:0]    in_complete_mul_idx,
    input wire [31:0]   in_complete_mul_value,
    input wire [2:0]    in_mul_exception,

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

// Original declaration
// rob_entry [ROB_SIZE-1:0] entries;

reg [31:0] PC          [ROB_SIZE-1:0];
reg [31:0] addr_miss   [ROB_SIZE-1:0];
reg [31:0] value       [ROB_SIZE-1:0];
reg [4:0]  rd          [ROB_SIZE-1:0];
reg        valid       [ROB_SIZE-1:0];
reg        complete    [ROB_SIZE-1:0];
reg [2:0]  exception   [ROB_SIZE-1:0];
reg [2:0]  instr_type  [ROB_SIZE-1:0];

reg [3:0] head;
reg [3:0] tail;
reg [3:0] count;

assign out_full = (count == ROB_SIZE);
assign out_alloc_idx = tail;

always @(*) begin
    //Case we complete an instruction
    if (valid[head] && complete[head]) begin
        if (exception[head] != 3'b0) begin
            out_PC <= PC[head];                         //Send to rm0
            out_miss_addr <= addr_miss[head];           //Send to rm1
        end else begin
            out_ready <= complete[head];
            out_value <= value[head];
            out_rd <= rd[head];
            out_exception <= exception[head];
            out_instr_type <= instr_type[head];
        end
    end    
end

always @(posedge clk) begin
    if (reset) begin              
        head <= 0;
        tail <= 0;
        count <= 0;
        out_ready <= 0;
        
        invalidate_rob();

    end else if (exception[head] != 3'b0) begin
        head <= 0;
        tail <= 0;
        count <= 0;
        out_ready <= 0;
        invalidate_rob();
    end

    else begin
        // Allocation. From decode. Only on non stalled cycles
        if (in_allocate && !out_full && !in_stall) begin
            PC[tail] <= in_PC;
            addr_miss[tail] <= in_addr_miss;
            rd[tail] <= in_rd;
            instr_type[tail] <= in_instr_type;
            valid[tail] <= 1;
            complete[tail] <= 0;
            exception[tail] <= 3'b0;
            
            tail <= (tail + 1) % ROB_SIZE;
            count <= count + 1;
        end
        
        // Completion. Even on stalled cycles (for now)
        if (in_complete) begin
            value[in_complete_idx] <= in_complete_value;
            complete[in_complete_idx] <= 1;
            exception[in_complete_idx] <= in_exception;
        end
        
        //Entry completed
        if (valid[head] && complete[head]) begin
            valid[head] <= 0;
            complete[head] <= 0;

            head <= (head + 1) % ROB_SIZE;
            count <= count - 1;
        end else begin
            out_ready <= 0;
        end
    end
end

task automatic invalidate_rob;
    for (int i = 0; i < ROB_SIZE; i++) begin
        valid[i] <= 0;
        complete[i] <= 0;
    end
endtask

endmodule
