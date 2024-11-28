`include "cache2.sv"

module cache_tb();
    // Parameters
    localparam CACHE_LINE_SIZE = 128;
    localparam NUM_SETS = 2;
    localparam NUM_WAYS = 2;

    // Clock and reset
    reg clk;
    reg reset;

    // Cache signals
    reg [31:0] in_addr;
    reg [31:0] in_write_data;
    reg in_write_en;
    reg in_read_en;
    reg [2:0] in_funct3;
    reg [CACHE_LINE_SIZE-1:0] in_mem_read_data;

    wire [31:0] out_read_data;
    wire out_hit;
    wire out_busy;
    wire out_mem_read_en;
    wire out_mem_write_en;
    wire [31:0] out_mem_addr;
    wire [CACHE_LINE_SIZE-1:0] out_mem_write_data;

    // Simulated memory
    reg [7:0] memory [1024];  // Byte addressable memory

    // Additional memory interface signals
    reg in_mem_ready;
    
    // Memory simulation counters
    reg [3:0] mem_wait_counter;
    reg mem_operation_pending;

    // Cache instance
    cache #(
        .CACHE_LINE_SIZE(CACHE_LINE_SIZE),
        .NUM_SETS(NUM_SETS),
        .NUM_WAYS(NUM_WAYS)
    ) dut (.*);

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Memory simulation
    always @(posedge clk) begin
        if (reset) begin
            in_mem_ready <= 0;
            mem_wait_counter <= 0;
            mem_operation_pending <= 0;
        end
        else begin
            // Start memory operation when read or write is requested
            if ((out_mem_read_en || out_mem_write_en) && !mem_operation_pending && mem_wait_counter == 0) begin
                mem_operation_pending <= 1;
                mem_wait_counter <= 1;  // Start at 1 instead of 0
                in_mem_ready <= 0;
            end
            
            // Count cycles for memory operation
            if (mem_operation_pending) begin
                if (mem_wait_counter == 9) begin  // 10 cycles total
                    in_mem_ready <= 1;
                    mem_operation_pending <= 0;
                    mem_wait_counter <= 0;  // Reset counter
                    
                    // If it's a read operation, prepare read data
                    if (out_mem_read_en) begin
                        for (int i = 0; i < CACHE_LINE_SIZE/8; i++) begin
                            in_mem_read_data[i*8 +: 8] <= memory[out_mem_addr + i];
                        end
                    end
                    // If it's a write operation, store data
                    if (out_mem_write_en) begin
                        for (int i = 0; i < CACHE_LINE_SIZE/8; i++) begin
                            memory[out_mem_addr + i] <= out_mem_write_data[i*8 +: 8];
                        end
                    end
                end 
                else begin
                    mem_wait_counter <= mem_wait_counter + 1;
                    in_mem_ready <= 0;
                end
            end
            else begin
                in_mem_ready <= 0;
            end
        end
    end

    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("cache_tb.vcd");
        $dumpvars(0, cache_tb);

        //Dump internal signals
        $dumpvars(0, dut.state);
        $dumpvars(0, dut.tag);
        $dumpvars(0, dut.set_index);
        $dumpvars(0, dut.word_offset);
        $dumpvars(0, dut.byte_offset);
        $dumpvars(0, dut.way_to_replace);
        // Initialize signals
        reset = 1;
        in_addr = 0;
        in_write_data = 0;
        in_write_en = 0;
        in_read_en = 0;
        in_funct3 = 0;
        in_mem_ready = 0;

        // Initialize memory with test data
        for (int i = 0; i < 1024; i++) begin
            memory[i] = i & 8'hFF;
        end

        // Reset sequence
        repeat(4) @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // **Test 1: Multiple Reads to Populate Cache**
        $display("\n=== Test 1: Multiple Reads to Populate Cache ===");
        // Read Address 0x00000100 (Set 0)
        @(posedge clk);
        #1;
        in_addr = 32'h00000100;
        in_read_en = 1;
        in_funct3 = 3'b010;  // LW
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_read_en = 0;
        
        // Read Address 0x00000104 (Set 0, different word)
        @(posedge clk);
        #1;
        in_addr = 32'h00000104;
        in_read_en = 1;
        in_funct3 = 3'b010;  // LW
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_read_en = 0;
        
        // Read Address 0x00000200 (Set 1)
        @(posedge clk);
        #1;
        in_addr = 32'h00000200;
        in_read_en = 1;
        in_funct3 = 3'b010;  // LW
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_read_en = 0;
        
        // **Test 2: Write Operations with Different Sizes**
        $display("\n=== Test 2: Write Operations with Different Sizes ===");
        // Write Byte to 0x00000100
        @(posedge clk);
        #1;
        in_addr = 32'h00000100;
        in_write_data = 32'hAA;
        in_write_en = 1;
        in_funct3 = 3'b100;  // SB
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_write_en = 0;
        
        // Write Halfword to 0x00000102
        @(posedge clk);
        #1;
        in_addr = 32'h00000102;
        in_write_data = 32'hBBBB;
        in_write_en = 1;
        in_funct3 = 3'b101;  // SH
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_write_en = 0;
        
        // Write Word to 0x00000100
        @(posedge clk);
        #1;
        in_addr = 32'h00000100;
        in_write_data = 32'hCCCCCCCC;
        in_write_en = 1;
        in_funct3 = 3'b110;  // SW
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_write_en = 0;
        
        // **Test 3: Repeated Reads to Confirm Hits**
        $display("\n=== Test 3: Repeated Reads to Confirm Hits ===");
        // Read Address 0x00000100 multiple times
        for (int i = 0; i < 3; i++) begin
            @(posedge clk);
            #1;
            in_addr = 32'h00000100;
            in_read_en = 1;
            in_funct3 = 3'b010;  // LW
            wait(!out_busy);
            @(posedge clk);
            #1;
            in_read_en = 0;
        end
        
        // **Test 4: Access Additional Addresses to Trigger Replacement**
        $display("\n=== Test 4: Access Additional Addresses to Trigger Replacement ===");
        // Read Address 0x00000300 (Set 0, should cause replacement if NUM_WAYS=2)
        @(posedge clk);
        #1;
        in_addr = 32'h00000300;
        in_read_en = 1;
        in_funct3 = 3'b010;  // LW
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_read_en = 0;
        
        // Read Address 0x00000400 (Set 0, another replacement)
        @(posedge clk);
        #1;
        in_addr = 32'h00000400;
        in_read_en = 1;
        in_funct3 = 3'b010;  // LW
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_read_en = 0;
        
        // **Test 5: Write-Back Verification**
        $display("\n=== Test 5: Write-Back Verification ===");
        // Write to an existing cache line to set dirty bit
        @(posedge clk);
        #1;
        in_addr = 32'h00000200;
        in_write_data = 32'hDDDDDDDD;
        in_write_en = 1;
        in_funct3 = 3'b110;  // SW
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_write_en = 0;
        
        // Read the same address to ensure data is written back
        @(posedge clk);
        #1;
        in_addr = 32'h00000200;
        in_read_en = 1;
        in_funct3 = 3'b010;  // LW
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_read_en = 0;
        
        // **Test 6: Invalid Address Access**
        $display("\n=== Test 6: Invalid Address Access ===");
        // Access an address outside the memory range
        @(posedge clk);
        #1;
        in_addr = 32'hFFFF_FFFF;
        in_read_en = 1;
        in_funct3 = 3'b010;  // LW
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_read_en = 0;
        
        // **Test 7: Simultaneous Read and Write**
        $display("\n=== Test 7: Simultaneous Read and Write ===");
        // Initiate a read and write to different addresses
        @(posedge clk);
        #1;
        // Write to 0x00000500
        in_addr = 32'h00000500;
        in_write_data = 32'hEEEEEEEE;
        in_write_en = 1;
        in_funct3 = 3'b110;  // SW
        // Simultaneously read from 0x00000100
        in_read_en = 1;
        wait(!out_busy);
        @(posedge clk);
        #1;
        in_write_en = 0;
        in_read_en = 0;
        
        // **Finalizing Testbench**
        $display("\n=== All Tests Completed ===");
        $finish;
    end

    // Monitor cache behavior every clock cycle
    always @(posedge clk) begin
        $display("\n=== Clock Cycle: %0d ===", $time/10);
        $display("State:");
        $display("  Reset: %b", reset);
        $display("  Cache State: %s", 
            dut.state == 2'b00 ? "IDLE" :
            dut.state == 2'b01 ? "MEM_READ" :
            dut.state == 2'b10 ? "MEM_WRITE" : "UNKNOWN");
        
        $display("\nInputs:");
        $display("  Address: 0x%h", in_addr);
        $display("  Read Enable: %b", in_read_en);
        $display("  Write Enable: %b", in_write_en);
        $display("  Write Data: 0x%h", in_write_data);
        $display("  Funct3: %b", in_funct3);
        
        $display("\nCache Status:");
        $display("  Hit: %b", out_hit);
        $display("  Busy: %b", out_busy);
        $display("  Read Data: 0x%h", out_read_data);
        
        $display("\nMemory Interface:");
        $display("  Memory Read Enable: %b", out_mem_read_en);
        $display("  Memory Write Enable: %b", out_mem_write_en);
        $display("  Memory Address: 0x%h", out_mem_addr);
        $display("  Memory Read Data: 0x%h", in_mem_read_data);
        $display("  Memory Ready: %b", in_mem_ready);
        
        $display("\nCache Internals:");
        $display("Full address: 0x%b", {dut.tag, dut.set_index, dut.word_offset, dut.byte_offset});
        $display("  Set Index: %b", dut.set_index);
        $display("  Tag: 0x%b", dut.tag);
        $display("  Word Offset: %b", dut.word_offset);
        $display("  Byte Offset: %b", dut.byte_offset);
        
        for (int i = 0; i < NUM_SETS; i++) begin
            for (int j = 0; j < NUM_WAYS; j++) begin
                $display("  Set %0d Way %0d:", i, j);
                $display("    Valid: %b", dut.valid[i][j]);
                $display("    Dirty: %b", dut.dirty[i][j]);
                $display("    Tag: 0x%b", dut.tags[i][j]);
                $display("    Data: 0x%h", dut.data[i][j]);
            end
            $display("    LRU: %b", dut.lru[i]);
        end
    end


endmodule