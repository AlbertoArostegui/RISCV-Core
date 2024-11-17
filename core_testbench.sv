`timescale 1ps/1ps
`include "core.sv"

module core_testbench();

    logic clk;
    logic reset;
    reg [31:0] r0;
    reg [31:0] r1;
    reg [31:0] r2;
    reg [31:0] r3;
    reg [31:0] r4;
    reg [31:0] r5;
    reg [31:0] r6;
    reg [31:0] r7;
    reg [31:0] r8;

    parameter MAX_CYCLES = 20;  // Reduced for testing
    integer cycle_count;

    // DUT instantiation
    core dut (
        .clk    (clk),
        .reset  (reset),
        .r0_out (r0),
        .r1_out (r1),
        .r2_out (r2),
        .r3_out (r3),
        .r4_out (r4),
        .r5_out (r5),
        .r6_out (r6),
        .r7_out (r7),
        .r8_out (r8)
    );

    // Initialize test program
    initial begin
        // Initialize instruction memory with test program
        dut.fetch.imemory.ROM[0] = 32'h00308093;  // addi x1, x1, 3
        dut.fetch.imemory.ROM[1] = 32'h00408113;  // addi x2, x1, 4
        dut.fetch.imemory.ROM[2] = 32'h002081b3;  // add  x3, x1, x2
    end

    // Clock and reset generation
    initial begin
        $display("Starting simulation...");
        
        // Initialize
        clk = 0;
        reset = 1;
        cycle_count = 0;

        // Hold reset for 2 cycles
        repeat(4) #1 clk = ~clk;
        
        // Release reset
        reset = 0;
        $display("Reset released, starting execution...\n");

        // Run for specified cycles
        repeat(MAX_CYCLES * 2) begin
            #1 clk = ~clk;
            if (clk) cycle_count = cycle_count + 1;
        end

        $display("\nSimulation finished after %0d cycles", cycle_count);
        $finish;
    end

    // Monitor Pipeline Stages
    always @(posedge clk) begin
        if (!reset) begin
            $display("\n=== Cycle %0d ===", cycle_count);
            
            // Fetch Stage
            $display("FETCH: PC=%h Instruction=%h", 
                dut.fetch_to_registers_pc,
                dut.fetch_to_registers_inst);

            // Decode Stage
            $display("DECODE: Instruction=%h rs1=%d rs2=%d rd=%d imm=%h",
                dut.instruction,
                dut.decode.RF.reg_a,
                dut.decode.RF.reg_b,
                dut.decode.out_rd,
                dut.decode.out_immediate);

            // Execute Stage
            $display("EXECUTE: ALU_out=%h Branch_taken=%b New_PC=%h",
                dut.EXMEM_to_memory_alu_out,
                dut.EXMEM_to_fetch_branch_taken,
                dut.EXMEM_to_fetch_PC);

            // Memory Stage
            $display("MEMORY: mem_read=%b mem_write=%b addr=%h data=%h",
                dut.EXMEM_to_memory_mem_read,
                dut.EXMEM_to_memory_mem_write,
                dut.EXMEM_to_memory_alu_out,
                dut.EXMEM_to_memory_mem_data);

            // Writeback Stage
            $display("WRITEBACK: rd=%d data=%h write_enable=%b",
                dut.writeback_to_decode_rd,
                dut.writeback_to_decode_out_data,
                dut.writeback_to_decode_write_enable);

            // Register File Status
            $display("REGISTERS: r0=%h r1=%h r2=%h r3=%h",
                r0, r1, r2, r3);
            $display("          r4=%h r5=%h r6=%h r7=%h r8=%h",
                r4, r5, r6, r7, r8);

            $fflush();  // Force output to display immediately
        end
    end

    // Dump waves
    initial begin
        $dumpfile("core_testbench.vcd");
        $dumpvars(0, core_testbench);
    end

endmodule
