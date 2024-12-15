module itlb (
    input clk,
    input reset,
    input [31:0] virtual_address,
    output reg [31:0] physical_address,
    output reg tlb_hit
);

    // Define the TLB entry structure
    typedef struct packed {
        logic [31:0] v_addr;
        logic [31:0] p_addr;
        logic valid;
    } tlb_entry_t;

    // Define the TLB array for instruction phase
    tlb_entry_t itlb [15:0];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            integer i;
            for (i = 0; i < 16; i = i + 1) begin
                itlb[i].valid <= 0;
            end
            physical_address <= 32'b0;
            tlb_hit <= 0;
        end else begin
            tlb_hit <= 0;
            for (int i = 0; i < 16; i = i + 1) begin
                if (itlb[i].valid && itlb[i].v_addr == virtual_address) begin
                    physical_address <= itlb[i].p_addr;
                    tlb_hit <= 1;
                    break;
                end
            end
        end
    end
endmodule