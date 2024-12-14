module store_buffer #(
    parameter SB_SIZE = 4
)(
    input clk,
    input reset,

    //INPUT
    input [31:0]        in_addr,
    input [31:0]        in_data,
    input [2:0]         in_funct3,
    input [3:0]         in_rob_idx,
    input               in_store_instr,
    input               in_load_instr,

    //ROB
    input               in_complete,                        //Instruction completed ? commit to cache    
    input [3:0]         in_complete_idx,                    //Index of completed instruction
    input               in_exception,                       //Exception, nuke the store buffer

    /*We need not store the store in the ROB. The ROB is used only for control*/

    
    //OUTPUT
    output reg [31:0]   out_addr,
    output reg [31:0]   out_data,
    output reg [2:0]    out_funct3,
    output reg          out_hit, //Control for selecting output of the Cache stage
    output reg          out_write_to_cache,
    output reg          out_stall
);

/*
66                35 34                  3   0
+-------------------+--------------------+---+
|   Address         |   Data             | F |
+-------------------+--------------------+---+
                                           |
                                           +-- funct3
*/

typedef struct packed {
    reg [31:0] addr;
    reg [31:0] data;
    reg [2:0]  funct3;
    reg [3:0]  rob_idx;
} sb_entry;

sb_entry [SB_SIZE-1:0] entries;
reg [1:0] store_counter; 
reg [1:0] oldest;

wire stall = in_store_inst && (store_counter == 2'b11);

always @(*) begin
    //Case full and new store enters -> Stall
    if (stall) out_stall <= 1;

    //Case rob indicates instr completion -> commit to cache
    else if (in_complete) begin
        for (int i = 0; i < SB_SIZE; i++) begin
            if (entries[i].rob_idx == in_complete_idx) begin
                out_addr <= entries[i].addr;
                out_data <= entries[i].data;
                out_funct3 <= entries[i].funct3;
                out_write_to_cache <= 1
            end
        end
    end

    //Case load instr -> check if addr in store buffer. This is sb bypass
    else if (in_load_instr) begin
        for (int i = 0; i < SB_SIZE; i++) begin
            if (entries[i].addr == in_addr) begin
                out_addr <= entries[i].addr;
                out_data <= entries[i].data;
                out_funct3 <= entries[i].funct3;
                out_hit <= 1;
            end
        end
    end
end

always @(posedge clk) begin
    if (reset || in_exception) reset();                                 //Case exception        --> Nuke Store Buffer (precise exceptions) or simply reset
    if (in_store_inst) begin                                            //Case we store         --> We save into the entries the store
        entries[store_counter].addr <= in_addr;
        entries[store_counter].data <= in_data;
        entries[store_counter].funct3 <= in_funct3;
        entries[store_counter].rob_idx <= in_rob_idx;
        store_counter <= store_counter + 1;
    if (out_hit) store_counter <= store_counter - 1;                    //Case we bypass load   --> We remove from our entries the data we loaded
    if (completed) store_counter <= store_counter - 1;                  //Case we write 2 cache --> We remove from our entries the data we are committing
end

task automatic reset;
    for (int i = 0; i < 3; i++) begin
        entries[i].addr <= 0;
        entries[i].data <= 0;
        entries[i].funct3 <= 0;
        entries[i].rob_idx <= 0;
    end
    store_counter <= 0;
    oldest <= 0;
endtask

endmodule
