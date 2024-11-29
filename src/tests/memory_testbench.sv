`include "memory.sv"

module memory_tb();
    // Parameters
    localparam CACHE_LINE_SIZE = 128;

    // Clock and reset
    reg clk;
    reg reset;

    // Memory signals
    reg in_mem_read_en;
    reg in_mem_write_en;
    reg [31:0] in_mem_addr;
    reg [127:0] in_mem_write_data;
    wire [127:0] out_mem_read_data;
    wire out_mem_ready;

    // Memory module instance
    memory_module dut (.*);

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("memory_tb.vcd");
        $dumpvars(0, memory_tb);

        // Display initial memory contents
        $display("\n=== Initial Memory Contents ===");
        $display("First 64 bytes (addresses 0x000-0x03F):");
        for (int i = 0; i < 4; i++) begin
            $write("0x%03x: ", i * 16);
            for (int j = 0; j < 16; j++) begin
                $write("%02h ", dut.memory[i*16 + j]);
            end
            $write("\n");
        end

        // Initialize signals
        reset = 1;
        in_mem_read_en = 0;
        in_mem_write_en = 0;
        in_mem_addr = 0;
        in_mem_write_data = 0;

        // Reset sequence
        repeat(4) @(posedge clk);
        reset = 0;
        @(posedge clk);

        // Test 1: Write to address 0x100
        $display("\n=== Test 1: Write to 0x100 ===");
        @(negedge clk);
        in_mem_addr = 32'h100;
        in_mem_write_data = {
            8'hFF, 8'hEE, 8'hDD, 8'hCC,
            8'hBB, 8'hAA, 8'h99, 8'h88,
            8'h77, 8'h66, 8'h55, 8'h44,
            8'h33, 8'h22, 8'h11, 8'h00
        };
        in_mem_write_en = 1;

        // Wait for write to complete
        do begin
            @(negedge clk);
        end while (!out_mem_ready);
        in_mem_write_en = 0;
        @(posedge clk);
        @(negedge clk);

        // Test 2: Read from address 0x100
        $display("\n=== Test 2: Read from 0x100 ===");
        in_mem_addr = 32'h100;
        in_mem_read_en = 1;

        // Wait for read to complete
        do begin
            @(negedge clk);
        end while (!out_mem_ready);
        in_mem_read_en = 0;
        @(posedge clk);
        @(negedge clk);

        // Test 3: Write to address 0x200
        $display("\n=== Test 3: Write to 0x200 ===");
        in_mem_addr = 32'h200;
        in_mem_write_data = {
            8'h00, 8'h11, 8'h22, 8'h33,
            8'h44, 8'h55, 8'h66, 8'h77,
            8'h88, 8'h99, 8'hAA, 8'hBB,
            8'hCC, 8'hDD, 8'hEE, 8'hFF
        };
        in_mem_write_en = 1;

        // Wait for write to complete
        do begin
            @(negedge clk);
        end while (!out_mem_ready);
        in_mem_write_en = 0;
        @(posedge clk);
        @(negedge clk);

        // Test 4: Read from address 0x200
        $display("\n=== Test 4: Read from 0x200 ===");
        in_mem_addr = 32'h200;
        in_mem_read_en = 1;

        // Wait for read to complete
        do begin
            @(negedge clk);
        end while (!out_mem_ready);
        in_mem_read_en = 0;

        // Add some cycles to observe final state
        repeat(4) @(posedge clk);
        
        $finish;
    end

    // Monitor memory behavior every clock cycle
    always @(posedge clk) begin
        $display("\n=== Clock Cycle: %0d ===", $time/10);
        $display("State:");
        $display("  Reset: %b", reset);
        $display("  Memory State: %s", 
            dut.state == 2'b00 ? "IDLE" :
            dut.state == 2'b01 ? "READ" :
            dut.state == 2'b10 ? "WRITE" : "UNKNOWN");
        $display("  Cycle Count: %0d", dut.cycle_count);
        
        $display("\nInputs:");
        $display("  Address: 0x%h", in_mem_addr);
        $display("  Read Enable: %b", in_mem_read_en);
        $display("  Write Enable: %b", in_mem_write_en);
        $display("  Write Data: 0x%h", in_mem_write_data);
        
        $display("\nOutputs:");
        $display("  Read Data: 0x%h", out_mem_read_data);
        $display("  Memory Ready: %b", out_mem_ready);

        // Display memory contents around the accessed address
        if (in_mem_addr != 0) begin
            $display("\nMemory Contents (±32 bytes around accessed address):");
            for (int i = -2; i <= 2; i++) begin
                $write("  0x%h: ", in_mem_addr + i*16);
                for (int j = 0; j < 16; j++) begin
                    $write("%h ", dut.memory[in_mem_addr + i*16 + j]);
                end
                $write("\n");
            end
        end
    end

endmodule
