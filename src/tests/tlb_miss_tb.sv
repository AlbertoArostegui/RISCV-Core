`include "tlb_miss.sv"

module tlb_miss_tb;

    reg clk;
    reg reset;
    reg [31:0] virtual_address;
    reg tlb_miss_detected;
    reg [31:0] os_offset;
    wire [31:0] physical_address;
    wire tlb_update;

    // Instantiate the tlb_miss module
    tlb_miss uut (
        .clk(clk),
        .reset(reset),
        .virtual_address(virtual_address),
        .tlb_miss_detected(tlb_miss_detected),
        .os_offset(os_offset),
        .physical_address(physical_address),
        .tlb_update(tlb_update)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        virtual_address = 32'h00000000;
        tlb_miss_detected = 0;
        os_offset = 32'h00001000;

        // Apply reset
        #10 reset = 0;

        // Test case 1: No TLB miss
        #10 tlb_miss_detected = 0;
        virtual_address = 32'h00002000;
        #10;

        // Test case 2: TLB miss with offset 0x1000
        #10 tlb_miss_detected = 1;
        virtual_address = 32'h00002000;
        os_offset = 32'h00001000;
        #10;

        // Test case 3: TLB miss with offset 0x2000
        #10 tlb_miss_detected = 1;
        virtual_address = 32'h00003000;
        os_offset = 32'h00002000;
        #10;

        // Test case 4: Reset
        #10 reset = 1;
        #10 reset = 0;
        #10;

        // Finish simulation
        $finish;
    end

    initial begin
        $monitor("Time: %0t | Reset: %b | TLB Miss Detected: %b | Virtual Address: %h | OS Offset: %h | Physical Address: %h | TLB Update: %b",
                 $time, reset, tlb_miss_detected, virtual_address, os_offset, physical_address, tlb_update);
    end
    
endmodule