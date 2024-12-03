module reorder_buffer #(
    parameter ROB_SIZE = 10
    ) (
    input clk,
    input reset,
    
    //INPUT
    input [31:0]        in_PC,
    input [31:0]        in_addr_miss,
    input [31:0]        in_value,
    input [5:0]         in_rd, //(dest)
    input [3:0]         in_idx,
    input [2:0]         in_inst_type,

    //OUTPUT
    output reg [31:0]   out_value,
    output reg [31:0]   out_miss_addr,
    output reg [31:0]   out_PC,
    output reg [4:0]    out_rd,

);

reg [3:0] head;
reg [3:0] tail;

typedef struct {
    reg [31:0]  PC;
    reg [31:0]  addr_miss;
    reg [31:0]  value;
    reg         rd;
    reg         valid;
    reg [2:0]   vec_exception;
} rob_entry;

rob_entry [ROB_SIZE-1:0] entries;

always @(*) begin
    
end

always @(posedge clk) begin
    
end



endmodule
