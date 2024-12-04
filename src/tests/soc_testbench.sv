`timescale 1ps/1ps
`include "SoC.sv"

module soc_testbench();

    logic clk;
    logic reset;
    
    SoC dut(
        .clk(clk),
        .reset(reset)
    );

    initial clk = 0;
    always #1 clk = ~clk;

    initial begin
        $dumpfile("soc_testbench.vcd");
        $dumpvars(0, soc_testbench);
        $dumpvars(0, dut);

        $readmemh("/Users/alberto/pa/src/tests/hex/loop_add_bne.hex", dut.memory.memory, 32'h80, 32'h87);
        /*
            addi x1, x0, 50
            addi x2, x0, 50
        loop:
            add x3, x3, x1
            addi x2, x2, -1	
            bne x2, x0, loop
        */

        for(int i = 32'h200; i < 32'h208; i = i+1) begin
            $display("%h",dut.memory.memory[i]);
        end

        reset = 1;
        #2 reset = 0;

        repeat(300) #2;
        $display("Register x0: %h", dut.core.decode.RF.registers[0]);
        $display("Register x1: %h", dut.core.decode.RF.registers[1]);
        $display("Register x2: %h", dut.core.decode.RF.registers[2]);   
        $display("Register x3: %h", dut.core.decode.RF.registers[3]);
        $finish;
    end


endmodule