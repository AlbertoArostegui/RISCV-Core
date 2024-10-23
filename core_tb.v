`timescale 1ms / 1ms
`include "core.v"

module bench();
    
    reg CLK;
    wire RESET = 0;
    wire [31:0] rd_out;
    wire [3:0] PC;
    wire [31:0] alu_out;
    wire [31:0] inst_out;

    core uut(.CLK(CLK), .RESET(RESET), .out(rd_out), .pc_out(PC), .alu_out(alu_out), .inst_out(inst_out));

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, bench);

        CLK = 0;
        forever begin
	        #200 CLK = ~CLK;
            $display("rd = %h, alu_out = %h, pc = %d", rd_out, alu_out, PC);
        end
    end
endmodule
