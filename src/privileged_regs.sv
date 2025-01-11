module privileged_regs(
    input clk,
    input reset,
    
    //INPUT
    input [2:0] in_rm_idx,      // rm0-rm4 
    input in_write_enable,
    input [31:0] in_write_data,

    input [2:0] in_exception_vector,
    input [31:0] in_fault_pc,
    input [31:0] in_fault_addr,
    input [31:0] in_additional_info,


    //OUTPUT
    output out_supervisor_mode,    // rm4[0]
    output reg out_overwrite_PC,
    output reg [31:0] out_new_address,
    output reg [2:0] out_exception_vector,
    output [31:0] out_rm1
);

    reg [31:0] rm [5];  // rm0-rm4
    assign out_supervisor_mode = rm[4][0];
    assign out_rm1 = rm[1];

    initial begin
        rm[0] = 32'h1000;
        rm[1] = 32'h0;
        rm[4] = 32'h1;  // Boot in supervisor mode
        out_overwrite_PC = 0;
        out_new_address = 0;
        out_exception_vector = 3'b0;
    end

    always @(*) begin
        if (in_rm_idx == 4) begin
            out_overwrite_PC = 1;
            out_new_address = rm[0];
        end
        if (in_exception_vector != 3'b000) begin
            out_new_address = 32'h2000;
            out_overwrite_PC = 1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            rm[4] <= 32'h1;  // Boot in supervisor mode
            out_overwrite_PC <= 0;
            out_new_address <= 0;
        end else begin
            if (in_exception_vector != 3'b000) begin
                rm[0] <= in_fault_pc;
                rm[1] <= in_fault_addr; 
                rm[2] <= in_additional_info;
                rm[4][0] <= 1;     // Switch to supervisor
                out_exception_vector <= in_exception_vector;
            end else if (in_write_enable) begin
                rm[in_rm_idx] <= in_write_data;
                if (in_rm_idx == 4) begin //If iret
                    out_new_address <= rm[0];
                end
            end else begin
                out_overwrite_PC <= 0;
                out_new_address <= 0;
            end
        end
    end

endmodule