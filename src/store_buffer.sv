module store_buffer(
    input clk,
    input reset,

    //INPUT
    input [31:0]        in_addr,
    input [31:0]        in_data,
    input [2:0]         in_funct3,
    input               in_store_inst,

    
    //OUTPUT
    output reg [31:0]   out_addr,
    output reg [31:0]   out_data,
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
reg [66:0] stores [0:3];
reg [1:0] store_counter; 
reg [1:0] oldest;

wire stall = in_store_inst && store_counter == 2'b11;
/*
always @(*) begin
    //Case full and new store enters -> Stall
    if (stall) begin
        out_stall <= 1;
    //Case not full store
    end else if (in_store_inst) begin
    end else if () begin
        
    end
end

always @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < 3; i++) begin
            stores[i] <= 63'd0;
            store_counter <= 2'b00;
        end        
    end else begin
        if (in_store_inst) begin
        end
    end
end
*/
endmodule
