`include "defines2.sv"
module reorder_buffer #(
    parameter ROB_SIZE = 10
    ) (
    input  wire         clk,
    input  wire         reset,
    
    //INPUT
    //From decode
    input  wire         in_allocate,
    input  wire [3:0]   in_allocate_idx,
    input  wire [31:0]  in_PC,
    input  wire         in_allocate_addr_miss,
    input  wire [3:0]   in_allocate_addr_miss_idx,
    input  wire [31:0]  in_addr_miss,
    input  wire [4:0]   in_rd,
    input  wire [2:0]   in_instr_type,

    //From execute
    input  wire         in_complete,
    input  wire [3:0]   in_complete_idx,
    input  wire [31:0]  in_complete_value,
    input  wire [2:0]   in_exception_vector,

    //From cache OR sb (LOADS)
    input wire          in_cache_complete,
    input wire [3:0]    in_cache_complete_idx,
    input wire [31:0]   in_cache_out,
    input wire [2:0]    in_cache_exception,

    //From mul
    input wire          in_mul_complete,
    input wire [3:0]    in_mul_complete_idx,
    input wire [31:0]   in_mul_complete_value,
    input wire [2:0]    in_mul_exception,

    //Control
    input wire          in_stall,

    //Bypass
    input wire [4:0]    in_execute_rs1,
    input wire [4:0]    in_execute_rs2,

    //Exception
    input wire [31:0]   in_addr_miss_instr,
    input wire [31:0]   in_addr_miss_data,
    
    //OUTPUT
    output reg          out_ready,
    output reg  [31:0]  out_value,
    output reg  [31:0]  out_miss_addr,
    output reg  [31:0]  out_PC,
    output reg  [4:0]   out_rd,
    output reg  [2:0]   out_exception_vector,
    output reg  [2:0]   out_instr_type,
    output reg          out_rob_nuke,
    
    //To decode
    output wire [3:0]   out_alloc_idx,
    //To cache
    output reg  [3:0]   out_complete_idx,    
    //Control
    output wire         out_full,

    //Supervisor
    output reg          out_priv_write_enable,
    output reg [2:0]    out_priv_rm_idx,
    output reg [31:0]   out_priv_write_data,

    //Bypass
    output reg          out_rs1_bypass,  
    output reg [31:0]   out_rs1_bypass_value,
    output reg          out_rs2_bypass,
    output reg [31:0]   out_rs2_bypass_value
);

/*We should take decisions according to instr_type. We should have at least
* ALU, STORE/LOAD and MUL*/


reg [31:0] PC          [ROB_SIZE-1:0];
reg [31:0] addr_miss   [ROB_SIZE-1:0];
reg [31:0] value       [ROB_SIZE-1:0];
reg [4:0]  rd          [ROB_SIZE-1:0];
reg        valid       [ROB_SIZE-1:0];
reg        complete    [ROB_SIZE-1:0];
reg [2:0]  exception   [ROB_SIZE-1:0];
reg [2:0]  instr_type  [ROB_SIZE-1:0];

reg [3:0] head;
//reg [3:0] in_allocate_idx;
reg [3:0] count;
reg [31:0] perf_counter;

assign out_full = (count == ROB_SIZE);
assign out_alloc_idx = in_allocate_idx;



reg [3:0] idx;
reg found_rs1;
reg found_rs2;

//BYPASSING
always @(*) begin
    out_rs1_bypass = 0;
    out_rs2_bypass = 0;
    out_rs1_bypass_value = 0;
    out_rs2_bypass_value = 0;

    // Start from newest entry (in_allocate_idx-1) and go backwards to head
    idx = (in_allocate_idx == 0) ? ROB_SIZE-1 : in_allocate_idx-1;
    found_rs1 = 0;
    found_rs2 = 0;

    while (idx != head && (!found_rs1 || !found_rs2)) begin
        if (!found_rs1 && valid[idx] && complete[idx] && in_execute_rs1 == rd[idx]) begin
            out_rs1_bypass = 1;
            out_rs1_bypass_value = value[idx];
            found_rs1 = 1;
        end
        if (!found_rs2 && valid[idx] && complete[idx] && in_execute_rs2 == rd[idx]) begin
            out_rs2_bypass = 1;
            out_rs2_bypass_value = value[idx];
            found_rs2 = 1;
        end
        idx = (idx == 0) ? ROB_SIZE-1 : idx-1;
    end

    // Check head position as well
    if (!found_rs1 && valid[head] && complete[head] && in_execute_rs1 == rd[head]) begin
        out_rs1_bypass = 1;
        out_rs1_bypass_value = value[head];
    end
    if (!found_rs2 && valid[head] && complete[head] && in_execute_rs2 == rd[head]) begin
        out_rs2_bypass = 1;
        out_rs2_bypass_value = value[head];
    end
end

always @(*) begin
    count = 0;
    out_PC = 0;
    out_miss_addr = 0;
    out_exception_vector = 3'b0;
    out_ready = 0;
    out_value = 0;
    out_rd = 0;
    out_instr_type = 0;
    out_complete_idx = 0;
    out_priv_write_enable = 0;
    out_priv_rm_idx = 0;
    out_priv_write_data = 0;
    for (int i = 0; i < ROB_SIZE; i++) begin
        if (valid[i]) count = count + 1;
    end
    for (int i = 0; i < ROB_SIZE; i++) begin
        if (complete[i] && !valid[i])
            complete[i] <= 0;
    end

    if (!in_stall && valid[head] && complete[head]) begin
        if (exception[head] == 3'b000) begin
            case (instr_type[head])
                `INSTR_TYPE_IRET: begin
                    out_ready = 0;
                    out_priv_write_enable = 1;
                    out_priv_rm_idx = 3'd4; //rm4
                    out_priv_write_data = 32'h0;
                    out_rob_nuke = 1;
                    head = 0;
                end
                `INSTR_TYPE_MOVRM: begin
                    out_ready = 0;
                    out_priv_write_enable = 1;
                    out_priv_rm_idx = rd[head];
                    out_priv_write_data = value[head];
                end
                default: begin
                    out_priv_write_enable <= 0;
                    out_ready = complete[head] && (instr_type[head] == `INSTR_TYPE_ALU || instr_type[head] == `INSTR_TYPE_MUL || instr_type[head] == `INSTR_TYPE_LOAD || instr_type[head] == `INSTR_TYPE_STORE);
                    out_value = value[head];
                    out_rd = rd[head];
                    out_exception_vector = exception[head];
                    out_instr_type = instr_type[head];
                    out_complete_idx = head;
                end
            endcase
        end 
        if (3'b001 == exception[head]) begin
            out_PC = PC[head];                         //Send to rm0
            out_miss_addr = PC[head];                  //Send to rm1
            out_exception_vector = exception[head];
            out_priv_write_enable = 1;
        end else if (exception[head] == `EXCEPTION_TYPE_DTLBMISS) begin
            out_PC = PC[head];                         //Send to rm0
            out_miss_addr = addr_miss[head];           //Send to rm1
            out_exception_vector = exception[head];
            out_priv_write_enable = 1;
        end
    end else begin
        out_ready = 0;
    end
end

always @(posedge clk) begin
    if (reset) begin              
        head <= 0;
        //in_allocate_idx <= 0;
        count <= 0;
        out_ready <= 0;
        perf_counter <= 0;
        
        invalidate_rob();
    end else if (!in_stall && exception[head] != 3'b0 && complete[head] && valid[head]) begin
        head <= 0;
        //in_allocate_idx <= 0;
        count <= 0;
        out_ready <= 0;
        invalidate_rob();
    end else begin
        
        out_rob_nuke <= 0;

        // Allocation. From decode. Once per cycle. Only on non-stalled cycles. 
        if (in_allocate && !out_full && !in_stall) begin
            PC[in_allocate_idx] <= in_PC;
            addr_miss[in_allocate_idx] <= in_addr_miss;
            if (in_instr_type == `INSTR_TYPE_STORE)
                rd[in_allocate_idx] <= 0;
            else 
                rd[in_allocate_idx] <= in_rd;
            instr_type[in_allocate_idx] <= in_instr_type;
            valid[in_allocate_idx] <= 1;
            complete[in_allocate_idx] <= 0;
            exception[in_allocate_idx] <= 3'b0;
            
            //in_allocate_idx <= (tail + 1) % ROB_SIZE;
            //count <= count + 1;
        end

        if (in_allocate_addr_miss) begin
            addr_miss[in_allocate_addr_miss_idx] <= in_addr_miss;
        end
        
        // Completion. Even on stalled cycles (for now)
        if (in_complete) begin
            value[in_complete_idx] <= in_complete_value;
            complete[in_complete_idx] <= 1;
            exception[in_complete_idx] <= in_exception_vector;
        end

        if (in_cache_complete) begin
            value[in_cache_complete_idx] <= in_cache_out;
            complete[in_cache_complete_idx] <= 1;
            exception[in_cache_complete_idx] <= in_cache_exception;
        end

        if (in_mul_complete) begin
            value[in_mul_complete_idx] <= in_mul_complete_value;
            complete[in_mul_complete_idx] <= 1;
            exception[in_mul_complete_idx] <= in_mul_exception;
        end
        
        //Entry completed
        if (!in_stall && valid[head] && complete[head]) begin
            valid[head] <= 0;
            complete[head] <= 0;
            rd[head] <= 0;
            exception[head] <= 0;
            value[head] <= 0;
            addr_miss[head] <= 0;
            perf_counter <= perf_counter + 1;

            head <= (head + 1) % ROB_SIZE;
            //if (count > 0) count <= count - 1 ;
        end else begin
            out_ready <= 0;
        end
        
    end
end

task automatic invalidate_rob;
    for (int i = 0; i < ROB_SIZE; i++) begin
        valid[i] <= 0;
        complete[i] <= 0;
        out_rob_nuke <= 1;
    end
endtask

endmodule
