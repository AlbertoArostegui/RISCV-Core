`timescale 1us / 1us
`include "core.v"

module bench();
    
    reg CLK;
    wire RESET = 0;
    wire [3:0] outs;

    core uut(.CLK(CLK), .RESET(RESET), .out(outs));

    reg[3:0] prev_LEDS = 0;
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, bench);

        CLK = 0;
        forever begin
	        #20 CLK = ~CLK;
            if(outs != prev_LEDS) begin
            $display("LEDS = %b", outs);
        end
	    prev_LEDS <= outs;
        end
    end
endmodule
