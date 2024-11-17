// Mandatory file to be able to launch SVUT flow
`timescale 1ns/1ps
`include "core.sv"

module core_testbench();


    logic clk;
    logic reset;
    reg [31:0] r1;

    // DUT instantiation
    core dut (
        .clk    (clk),
        .reset  (reset),
        .r1_out (r1)
    );
    // Dump waves
    initial clk = 0;
    always #1 clk = ~clk;

    initial begin
        $dumpfile("core_testbench.vcd");
        $dumpvars(0, core_testbench);
    end

    task setup(string msg="");
        begin
            // setup() runs when a test begins
        end
    endtask

    task teardown(string msg="");
        begin
            // teardown() runs when a test ends
        end
    endtask

endmodule
