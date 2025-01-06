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

reg [1:0] store_counter; 
reg [1:0] oldest;

initial begin
    reset_sb();
end

wire stall = in_store_instr && (store_counter == 2'b11);

initial out_stall <= 0;

always @(*) begin
    //Case full and new store enters -> Stall
    out_hit <= 0;
    out_addr <= 0;
    out_data <= 0;
    out_funct3 <= 0;
    out_write_to_cache <= 0;
    if (stall) out_stall <= 1;

    //Case rob indicates instr completion -> commit to cache
    else if (in_complete) begin
        for (int i = 0; i < SB_SIZE; i++) begin
            if (rob_idx[i] == in_complete_idx) begin
                out_addr <= addr[i];
                out_data <= data[i];
                out_funct3 <= funct3[i];
                out_write_to_cache <= 1;
            end
        end
    end

    //Case load instr -> check if addr in store buffer. This is sb bypass
    //TODO: SB bypass. Handle case in which we have more than one store for the same addr. Youngest should be returned.
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
end

//TODO: Drain store buffer. Figure out when is it needed to drain.
always @(posedge clk) begin
    if (reset || in_exception_vector != 3'b000) reset_sb();                              //Case exception        --> Nuke Store Buffer (precise exceptions) or simply reset
    else if (in_store_instr) begin                                                          //Case we store         --> We save into the entries the store
        addr[store_counter] <= in_addr;
        data[store_counter] <= in_data;
        funct3[store_counter] <= in_funct3;
        rob_idx[store_counter] <= in_rob_idx;
        valid[store_counter] <= 1;
        store_counter <= store_counter + 1;
    end
    if (in_complete) begin
        for (int i = 0; i < SB_SIZE; i++) begin
            if (rob_idx[i] == in_complete_idx) valid[i] <= 0;
        end
        store_counter <= store_counter - 1;                //Case we commit 2 cache --> We remove from our entries the data we are committing
    end
end

task reset_sb;
    for (int i = 0; i < 3; i++) begin
        addr[i] <= 0;
        data[i] <= 0;
        funct3[i] <= 0;
        rob_idx[i] <= 0;
        valid[i] <= 0;
    end
    store_counter <= 0;
    oldest <= 0;
endtask

endmodule
