`timescale 1ms / 1ms
`include "corev2.v"

module bench();
    
    reg CLK;
    wire [31:0] PC;
    wire [31:0] IR;
    wire [31:0] AluIn1;
    wire [31:0] AluIn2;
    wire [31:0] AluOut;

    core uut(.clk(CLK), .OUT_PC(PC), .OUT_IR(IR), .OUT_AluIn1(AluIn1), .OUT_AluIn2(AluIn2), .OUT_AluOut(AluOut));

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, bench);

        CLK = 0;
        forever begin
	        #200 CLK = ~CLK;
            $display("PC = %b, IR = %b, AluIn1 = %b, AluIn2 = %b, AluOut = %b", PC, IR, AluIn1, AluIn2, AluOut);
        end
    end
endmodule
