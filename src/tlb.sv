module tlb (
    input clk,
    input reset,
    input mode, // 0 for INSTRUCTION, 1 for DATA
    input [31:0] virtual_address,
    output [31:0] physical_address,
    output tlb_hit
);

    // Instantiate the instruction TLB
    itlb itlb_inst (
        .clk(clk),
        .reset(reset),
        .virtual_address(virtual_address),
        .physical_address(physical_address_itlb),
        .tlb_hit(tlb_hit_itlb)
    );

    // Instantiate the data TLB
    dtlb dtlb_inst (
        .clk(clk),
        .reset(reset),
        .virtual_address(virtual_address),
        .physical_address(physical_address_dtlb),
        .tlb_hit(tlb_hit_dtlb)
    );

    // Output logic
    assign physical_address = (mode == 0) ? physical_address_itlb : physical_address_dtlb;
    assign tlb_hit = (mode == 0) ? tlb_hit_itlb : tlb_hit_dtlb;

endmodule

