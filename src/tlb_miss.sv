module tlb_miss (
    input clk,
    input reset,
    input [31:0] virtual_address,
    input tlb_miss_detected,
    input [31:0] os_offset, 
    output reg [31:0] physical_address,
    output reg tlb_update
);

    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            physical_address <= 32'b0;
            tlb_update <= 0;
        end else if (tlb_miss_detected) begin
            physical_address <= virtual_address + os_offset; 
            tlb_update <= 1;
        end else begin
            tlb_update <= 0;
        end
    end

endmodule