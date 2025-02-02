`include "cache.sv"
`include "memory.sv"

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
    wire [31:0] out_read_data;
    wire out_hit;
    wire out_busy;
    wire out_mem_read_en;
    wire out_mem_write_en;
    wire [31:0] out_mem_addr;
    wire [CACHE_LINE_SIZE-1:0] out_mem_write_data;

    // Memory module signals
    wire [CACHE_LINE_SIZE-1:0] in_mem_read_data;
    wire in_mem_ready;

    // Cache instance
    cache #(
        .CACHE_LINE_SIZE(CACHE_LINE_SIZE),
        .NUM_SETS(NUM_SETS),
        .NUM_WAYS(NUM_WAYS)
    ) dut (.*);

    // Memory module instance
    memory_module mem (
        .clk(clk),
        .reset(reset),
        .in_mem_read_en(out_mem_read_en),
        .in_mem_write_en(out_mem_write_en),
        .in_mem_addr(out_mem_addr),
        .in_mem_write_data(out_mem_write_data),
        .out_mem_read_data(in_mem_read_data),
        .out_mem_ready(in_mem_ready)
    );

    reg [31:0] clk_count = 0;
    // Clock generation
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("cache_tb.vcd");
        $dumpvars(0, cache_tb);

        // Dump internal signals
        $dumpvars(0, dut.state);
        $dumpvars(0, dut.tag);
        $dumpvars(0, dut.set_index);
        $dumpvars(0, dut.word_offset);
        $dumpvars(0, dut.byte_offset);
        $dumpvars(0, dut.way_to_replace);

        $dumpvars(0, mem.state);
        $dumpvars(0, mem.cycle_count);

        // Initialize memory with test patterns
        for (int i = 0; i < 1024*16; i++) begin  // Note: multiplied by 16 for byte addressing
            mem.memory[i] = i & 8'hFF;
        end

        mem.memory['h208] = 8'hAA;
        mem.memory['h209] = 8'hBB;
        mem.memory['h20A] = 8'hCC;
        mem.memory['h20B] = 8'hDD;
        mem.memory['h20C] = 8'hEE;
        mem.memory['h20D] = 8'hFF;
        mem.memory['h20E] = 8'h11;
        mem.memory['h20F] = 8'h22;
        mem.memory['h210] = 8'h33;
        mem.memory['h211] = 8'h44;
        mem.memory['h212] = 8'h55;
        mem.memory['h213] = 8'h66;
        mem.memory['h214] = 8'h77;
        mem.memory['h215] = 8'h88;
        mem.memory['h216] = 8'h99;
        mem.memory['h217] = 8'h00;
        

        // Verify memory initialization
        $display("\n=== Initial Memory Contents ===");
        // Show memory around 0x100
        $display("Memory around 0x100:");
        for (int i = 0; i < 32; i++) begin
            if (i % 16 == 0) $write("0x%03x: ", 'h100 + i);
            $write("%02h ", mem.memory['h100 + i]);
            if (i % 16 == 15) $write("\n");
        end
        $display("Memory at 0x200:");
        for (int i = 0; i < 32; i++) begin
            if (i % 16 == 0) $write("0x%03x: ", 'h200 + i);
            $write("%02h ", mem.memory['h200 + i]);
            if (i % 16 == 15) $write("\n");
        end

        // Initialize signals
        reset = 1;
        in_addr = 0;
        in_write_data = 0;
        in_write_en = 0;
        in_read_en = 0;
        in_funct3 = 0;

        // Wait for memory initialization to complete
        #1;

        // Reset sequence
        repeat(4) @(posedge clk);
        reset = 0;
        @(posedge clk);
        /*
        // Test 1: Read from 0x00000100 (Set 0)
        $display("\n=== Test 1: Read from 0x00000100 ===");
        @(posedge clk);
        in_addr = 32'h00000100;
        in_read_en = 1;
        in_funct3 = 3'b010;  // LW
        
        // Wait for first operation to complete
        do begin
            @(posedge clk);
        end while (out_busy);
        
        // Immediately test the next address in same cache line
        $display("\n=== Test 2: Read from 0x00000104 (same cache line) ===");
        in_addr = 32'h00000104;
        // in_read_en is still 1
        
        // Should be a hit, so no need to wait for busy
        @(posedge clk);  // Data should be available next cycle
        if (!out_hit) $display("ERROR: Should be a cache hit!");

        // Test 3: Read from 0x00000208 (Set 0)
        $display("\n=== Test 3: Read from 0x00000208 ===");
        in_addr = 32'h00000208;
        in_read_en = 1;  // Set read_en again
        
        // Wait for third operation to complete
        do begin
            @(posedge clk);
        end while (out_busy);
        @(posedge clk);
        @(posedge clk);
        in_read_en = 0;  // Clear read_en
        */
        // Test 1: Read from 0x00000100 (Set 0)
        @(posedge clk);
        in_addr <= 32'h00000100;
        in_read_en <= 1;
        in_funct3 <= 3'b010;  // LW
        
        do begin
            @(posedge clk);
        end while (out_busy);
        
        // Test 2: Write to 0x00000204 (Set 0)
        in_read_en <= 0;
        in_write_data <= 32'h00011000;
        in_write_en <= 1;
        in_addr <= 32'h00000204;
        in_funct3 <= 3'b010;
        
        do begin
            @(posedge clk);
        end while (out_busy);

        // Test 3: Read from 0x00000120 (Set 0)
        in_write_en <= 0;
        in_read_en <= 1;
        in_write_data <= 32'h00000000;
        in_addr <= 32'h00000120;
        in_funct3 <= 3'b010;

        do begin
            @(posedge clk);
        end while (out_busy);

        // Test 4: Read from 0x00000204 (Set 0)
        in_read_en <= 1;
        in_addr <= 32'h00000204;
        in_funct3 <= 3'b010;
        
        // Add some cycles to observe final state
        repeat(35) @(posedge clk);
        
        $finish;
    end

    // Monitor cache behavior every clock cycle
    always @(posedge clk) begin
        clk_count <= clk_count + 1;
        $display("\n=== Clock Cycle: %0d ===", clk_count);
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