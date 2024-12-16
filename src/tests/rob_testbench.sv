`timescale 1ns/1ps
`include "reorder_buffer_alt.sv"

module reorder_buffer_tb();
    // Parameters
    parameter ROB_SIZE = 10;

    // Signals
    logic clk;
    logic reset;
    
    // Decode inputs
    logic         in_allocate;
    logic [31:0]  in_PC;
    logic [31:0]  in_addr_miss;
    logic [4:0]   in_rd;
    logic [2:0]   in_instr_type;

    // Execute inputs
    logic         in_complete;
    logic [3:0]   in_complete_idx;
    logic [31:0]  in_complete_value;
    logic [2:0]   in_exception;

    // Cache inputs
    logic [31:0]  in_cache_out;
    logic [3:0]   in_complete_cache_idx;
    logic [4:0]   in_cache_rd;

    // Control input
    logic         in_stall;
    
    // Outputs
    logic         out_ready;
    logic [31:0]  out_value;
    logic [31:0]  out_miss_addr;
    logic [31:0]  out_PC;
    logic [4:0]   out_rd;
    logic [2:0]   out_exception;
    logic [2:0]   out_instr_type;
    logic         out_full;
    logic [3:0]   out_alloc_idx;

    // DUT instantiation
    reorder_buffer #(
        .ROB_SIZE(ROB_SIZE)
    ) dut (.*);

    // Clock generation
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // Monitor task
    task automatic display_rob_state;
        $display("\n=== ROB State at time %0t ===", $time);
        $display("Head: %0d, Tail: %0d, Count: %0d", dut.head, dut.tail, dut.count);
        $display("Full: %b, Alloc Index: %0d", out_full, out_alloc_idx);
        
        for (int i = 0; i < ROB_SIZE; i++) begin
            if (dut.valid[i]) begin
                $display("Entry %0d:", i);
                $display("  PC: %h", dut.PC[i]);
                $display("  Value: %h", dut.value[i]);
                $display("  RD: %0d", dut.rd[i]);
                $display("  Valid: %b", dut.valid[i]);
                $display("  Complete: %b", dut.complete[i]);
                $display("  Exception: %b", dut.exception[i]);
                $display("  Instr Type: %b", dut.instr_type[i]);
            end
        end
        $display("=====================================\n");
    endtask

    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("reorder_buffer_tb.vcd");
        $dumpvars(0, reorder_buffer_tb);

        // Initialize inputs
        reset = 1;
        in_allocate = 0;
        in_PC = 0;
        in_addr_miss = 0;
        in_rd = 0;
        in_instr_type = 0;
        in_complete = 0;
        in_complete_idx = 0;
        in_complete_value = 0;
        in_exception = 0;
        in_cache_out = 0;
        in_complete_cache_idx = 0;
        in_cache_rd = 0;
        in_stall = 0;

        // Reset sequence
        @(posedge clk);
        #1 reset = 0;
        
        // Test Case 1: Allocate ALU instruction
        $display("\nTest Case 1: Allocate ALU instruction");
        @(posedge clk);
        in_allocate = 1;
        in_PC = 32'h1000;
        in_rd = 5'd1;
        in_instr_type = 3'b000; // ALU type
        @(posedge clk);
        in_allocate = 0;
        display_rob_state();

        // Test Case 2: Complete ALU instruction
        $display("\nTest Case 2: Complete ALU instruction");
        @(posedge clk);
        in_complete = 1;
        in_complete_idx = 0;
        in_complete_value = 32'hDEADBEEF;
        @(posedge clk);
        in_complete = 0;
        display_rob_state();

        // Test Case 3: Allocate Load instruction
        $display("\nTest Case 3: Allocate Load instruction");
        @(posedge clk);
        in_allocate = 1;
        in_PC = 32'h1004;
        in_rd = 5'd2;
        in_instr_type = 3'b001; // Load type
        @(posedge clk);
        in_allocate = 0;
        display_rob_state();

        // Test Case 4: Complete Load instruction with cache
        $display("\nTest Case 4: Complete Load instruction with cache");
        @(posedge clk);
        in_cache_out = 32'hCAFEBABE;
        in_complete_cache_idx = 1;
        in_cache_rd = 5'd2;
        @(posedge clk);
        display_rob_state();

        // Test Case 5: Test exception handling
        $display("\nTest Case 5: Test exception handling");
        @(posedge clk);
        in_allocate = 1;
        in_PC = 32'h1008;
        in_rd = 5'd3;
        in_instr_type = 3'b000;
        in_addr_miss = 32'hFFFF0000;
        @(posedge clk);
        in_allocate = 0;
        in_complete = 1;
        in_complete_idx = 2;
        in_exception = 3'b001;
        @(posedge clk);
        in_complete = 0;
        display_rob_state();

        // Test Case 6: Test full condition
        $display("\nTest Case 6: Test full condition");
        repeat(ROB_SIZE) begin
            @(posedge clk);
            in_allocate = 1;
            in_PC = in_PC + 4;
            in_rd = in_rd + 1;
            @(posedge clk);
            display_rob_state();
        end

        // Test Case 7: Test stall behavior
        $display("\nTest Case 7: Test stall behavior");
        in_stall = 1;
        @(posedge clk);
        in_allocate = 1;
        in_PC = 32'h2000;
        in_rd = 5'd10;
        @(posedge clk);
        in_stall = 0;
        in_allocate = 0;
        display_rob_state();

        // Add some cycles to observe final state
        repeat(5) @(posedge clk);
        
        $finish;
    end

    // Monitor outputs
    always @(posedge clk) begin
        if (!reset) begin
            $display("\nOutputs at time %0t:", $time);
            $display("Ready: %b", out_ready);
            $display("Value: %h", out_value);
            $display("Miss Addr: %h", out_miss_addr);
            $display("PC: %h", out_PC);
            $display("RD: %d", out_rd);
            $display("Exception: %b", out_exception);
            $display("Instr Type: %b", out_instr_type);
        end
    end

endmodule