`include "defines2.sv"
module tlb #(
    parameter int N = 4
)(
    input clk,
    input reset,

    //INPUT
    input               in_supervisor_mode,
    input [31:0]        in_virtual_address,

    input               in_write_enable,
    input [31:0]        in_write_virtual_address,
    input [31:0]        in_write_physical_address,

    //OUTPUT
    output reg [31:0]   out_fault_addr,
    output reg [31:0]   out_physical_address,
    output reg          out_tlb_hit,
    output reg [2:0]    out_exception_vector
);

    /*
    typedef struct packed {
        logic [31:0] v_addr;
        logic [19:0] p_addr;
        logic valid;
    } tlb_entry_t;
    tlb_entry_t entries [N-1:0];
    */
    reg [19:0] v_addr [N-1:0];
    reg [19:0] p_addr [N-1:0];
    reg valid [N-1:0];

    reg [$clog2(N)-1:0] replace_ptr;

    always @(*) begin
        out_tlb_hit = 0;
        out_exception_vector = 0;
        out_physical_address = 0;
        out_fault_addr = 0;
        if (!in_supervisor_mode) begin
            for (int i = 0; i < N; i = i + 1) begin
                if (valid[i] && v_addr[i] == (in_virtual_address[19:0])) begin
                    out_tlb_hit = 1;
                    out_physical_address = {p_addr[i], in_virtual_address[11:0]};
                end
            end
            if (!out_tlb_hit) begin
                out_exception_vector = 3'b000;
                out_fault_addr = in_virtual_address;
            end
        end else begin
            out_physical_address = in_virtual_address;
            out_tlb_hit = 1;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            integer i;
            for (i = 0; i < 16; i = i + 1) begin
                valid[i] <= 0;
            end
            replace_ptr <= 0;
        end else if (in_write_enable) begin
            if (in_supervisor_mode) begin
                valid[replace_ptr] <= 1;
                v_addr[replace_ptr] <= in_write_virtual_address[19:0];
                p_addr[replace_ptr] <= in_write_physical_address[19:0];
                replace_ptr <= replace_ptr + 1;
            end else out_exception_vector <= `EXCEPTION_TYPE_PRIV;
        end
    end
endmodule
