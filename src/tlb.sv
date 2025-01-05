module tlb #(
    parameter int N = 4
)(
    input clk,
    input reset,

    //INPUT
    input               supervisor_mode,
    input [31:0]        virtual_address,

    input               write_enable,
    input [31:0]        write_virtual_address,
    input [19:0]        write_physical_address,

    //OUTPUT
    output reg [31:0]   physical_address,
    output reg          tlb_hit,
    output reg          page_fault,
);

    typedef struct packed {
        logic [31:0] v_addr;
        logic [19:0] p_addr;
        logic valid;
    } tlb_entry_t;

    tlb_entry_t tlb [N-1:0];
    reg [$clog2(N)-1:0] replace_ptr;

    always @(*) begin
        hit = 0;
        fault = 0;
        physical_address = 0;
        if (!supervisor_mode) begin
            for (int i = 0; i < N; i = i + 1) begin
                if (tlb[i].valid && tlb[i].v_addr == virtual_address) begin
                    hit = 1;
                    physical_address = tlb[i].p_addr;
                    break;
                end
            end
            if (!hit) begin
                fault = 1;
            end
        end else begin
            physical_address = virtual_address[19:0];
            hit = 1;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            integer i;
            for (i = 0; i < 16; i = i + 1) begin
                dtlb[i].valid <= 0;
            end
            replace_ptr <= 0;
        end else (write_enable) begin
            entries[replace_ptr].valid <= 1;
            entries[replace_ptr].v_addr <= write_virtual_address;
            entries[replace_ptr].p_addr <= write_physical_address;
            replace_ptr <= replace_ptr + 1;
        end
    end
endmodule
