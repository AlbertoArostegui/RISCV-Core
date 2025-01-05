module privileged_regs(
    input clk,
    input reset,
    
    //INPUT
    input [2:0] rm_idx,      // rm0-rm4 
    input write_enable,
    input [31:0] write_data,

    input exception,
    input [31:0] fault_pc,
    input [31:0] fault_addr,
    input [31:0] additional_info


    //OUTPUT
    output reg [31:0] read_data,
    output reg supervisor_mode,    // rm4[0]
);

    reg [31:0] rm [5];  // rm0-rm4


    always @(*) begin
        read_data = rm[rm_idx];
    end

    always @(posedge clk) begin
        if (reset) begin
            rm[4] <= 32'h1;  // Boot in supervisor mode
            supervisor_mode <= 1;
        end else begin
            if (exception) begin
                rm[0] <= fault_pc;
                rm[1] <= fault_addr; 
                rm[2] <= additional_info;
                rm[4][0] <= 1;     // Switch to supervisor
                supervisor_mode <= 1;
            end else if (write_enable) begin
                rm[rm_idx] <= write_data;
                if (rm_idx == 4) begin
                    supervisor_mode <= write_data[0];
                end
            end
        end
    end

endmodule