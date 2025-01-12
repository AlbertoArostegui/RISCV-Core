module store_buffer #(
    parameter SB_SIZE = 4
)(
    input clk,
    input reset,

    //INPUT
    input [31:0]        in_addr,
    input [31:0]        in_data,
    input [2:0]         in_funct3,
    input               in_store_instr,
    input               in_load_instr,
    input               in_cache_stall,

    //ROB
    input [3:0]         in_rob_idx,                         //Allocate
    input               in_complete,                        //Instruction completed ? commit to cache    
    input [3:0]         in_complete_idx,                    //Index of completed instruction
    input [2:0]         in_exception_vector,                //Exception, nuke the store buffer

    /*The ROB is used only for control*/

    
    //OUTPUT
    output reg [31:0]   out_addr,
    output reg [31:0]   out_data,
    output reg [2:0]    out_funct3,
    output reg          out_hit, //Control for selecting output of the Cache stage
    output reg          out_write_to_cache,
    output reg          out_stall
);
/* Original, but icarus verilog does not support iterating packed structs
typedef struct packed {
    reg [31:0] addr;
    reg [31:0] data;
    reg [2:0]  funct3;
    reg [3:0]  rob_idx;
} sb_entry;

sb_entry [SB_SIZE-1:0] entries;
*/

// Individual arrays instead of structure
reg [31:0] addr      [SB_SIZE-1:0];
reg [31:0] data      [SB_SIZE-1:0];
reg [2:0]  funct3    [SB_SIZE-1:0];
reg [3:0]  rob_idx   [SB_SIZE-1:0];
reg        valid     [SB_SIZE-1:0];

reg [1:0] store_idx;
reg [1:0] store_counter; 
reg [1:0] oldest;

initial begin
    reset_sb();
end

wire stall = in_store_instr && (store_counter == 2'b11);

initial out_stall <= 0;

always @(*) begin
    //Case full and new store enters -> Stall
    /*
    out_hit <= 0;
    out_addr <= 0;
    out_data <= 0;
    out_funct3 <= 0;
    out_write_to_cache <= 0;
    */

    if (stall) out_stall <= 1;
    else if (in_load_instr) begin
        for (int i = 0; i < SB_SIZE; i++) begin
            if (valid[i] && addr[i] == in_addr) begin
                out_addr <= addr[i];
                out_data <= data[i];
                out_funct3 <= funct3[i];
                out_hit <= 1;
            end
        end
    end
    for (int i = 0; i < SB_SIZE; i++) begin
        if (valid[i]) begin
            store_counter = store_counter + 1;
        end
    end
end



//TODO: Drain store buffer. Figure out when is it needed to drain.
always @(posedge clk) begin
    if (reset || in_exception_vector != 3'b000) reset_sb();                              //Case exception        --> Nuke Store Buffer (precise exceptions) or simply reset
    else if (in_store_instr) begin                                                          //Case we store         --> We save into the entries the store
        addr[store_idx] <= in_addr;
        data[store_idx] <= in_data;
        funct3[store_idx] <= in_funct3;
        rob_idx[store_idx] <= in_rob_idx;
        valid[store_idx] <= 1;
        store_idx <= store_idx + 1;
    end
    if (in_complete) begin    
        for (int i = 0; i < SB_SIZE; i++) begin
            if (rob_idx[i] == in_complete_idx && valid[i]) begin
                out_addr <= addr[i];
                out_data <= data[i];
                out_funct3 <= funct3[i];
                out_write_to_cache <= 1;
                valid[i] <= 0;
            end
        end
        store_idx <= store_idx - 1;                //Case we commit 2 cache --> We remove from our entries the data we are committing
    end else begin
        if (out_write_to_cache && !in_cache_stall)
            out_write_to_cache <= 0;
    end
end

task reset_sb;
    for (int i = 0; i < SB_SIZE; i++) begin
        addr[i] <= 0;
        data[i] <= 0;
        funct3[i] <= 0;
        rob_idx[i] <= 0;
        valid[i] <= 0;
    end
    store_idx <= 0;
    store_counter <= 0;
    oldest <= 0;
    out_data <= 0;
    out_hit <= 0;
    out_addr <= 0;
endtask

endmodule
