`timescale 1ps/1ps
`include "core.sv"

module core_testbench();

    logic clk;
    logic reset;

    parameter MAX_CYCLES = 8;  // Reduced for testing
    integer cycle_count;

    // DUT instantiation
    core dut (
        .clk    (clk),
        .reset  (reset)
    );

    // Initialize test program
    initial begin
        // Initialize instruction memory with test program
        dut.fetch.imemory.ROM[0] = 32'h00100093;  // addi x1, x0, 1
        dut.fetch.imemory.ROM[1] = 32'h00200113;  // addi x2, x0, 2
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
            $display("========================================================\n=== Cycle %0d ===\n========================================================\n", cycle_count);
            
            // Fetch Stage
            $display("FETCH: out_PC=%h out_instruction=%h", 
                dut.fetch_to_registers_pc,
                dut.fetch_to_registers_inst);

            //Fetch to Decode registers
            $display("Registers IFID: out_PC=%h out_instruction=%h", 
                dut.registers_IFID.out_PC,
                dut.registers_IFID.out_instruction);

            $display("\n========================================\n");
            
            // Decode Stage
            $display("DECODE: Instruction=%h rs1=%d rs2=%d rd=%d imm=%h\nout_alu_src=%b out_alu_op=%b out_mem_write=%b out_mem_read=%b\nout_branch_inst=%b out_mem_to_reg=%b out_write_enable=%b out_funct7=%b out_funct3=%b out_opcode=%b out_instr_type=%b\n",
                dut.decode_to_registers_instruction,
                dut.decode_to_registers_data_a,
                dut.decode_to_registers_data_b,
                dut.decode_to_registers_rd,
                dut.decode_to_registers_immediate,
                dut.decode_to_registers_EX_alu_src,
                dut.decode_to_registers_EX_alu_op,
                dut.decode_to_registers_MEM_mem_write,
                dut.decode_to_registers_MEM_mem_read,
                dut.decode_to_registers_MEM_branch_inst,
                dut.decode_to_registers_WB_write_mem_to_reg,
                dut.decode_to_registers_WB_write_enable,
                dut.decode_to_registers_funct7,
                dut.decode_to_registers_funct3,
                dut.decode_to_registers_opcode,
                dut.decode_to_registers_instr_type);
            
            // Decode to Execute registers
            $display("Registers IDEX: Instruction=%h PC=%h immediate=%h\nrs1=%d rs2=%d rd=%d\n alu_src=%b alu_op=%b mem_write=%b mem_read=%b branch_inst=%b mem_to_reg=%b\n out_write_enable=%b out_funct7=%b out_funct3=%b out_opcode=%b out_instr_type=%b\n",
                dut.registers_IDEX.out_instruction,
                dut.registers_IDEX.out_PC,
                dut.registers_IDEX.out_immediate,
                dut.registers_IDEX.out_rs1,
                dut.registers_IDEX.out_rs2,
                dut.registers_IDEX.out_rd,
                dut.registers_IDEX.out_alu_src,
                dut.registers_IDEX.out_alu_op,
                dut.registers_IDEX.out_mem_write,
                dut.registers_IDEX.out_mem_read,
                dut.registers_IDEX.out_branch_inst,
                dut.registers_IDEX.out_mem_to_reg,
                dut.registers_IDEX.out_write_enable,
                dut.registers_IDEX.out_funct7,
                dut.registers_IDEX.out_funct3,
                dut.registers_IDEX.out_opcode,
                dut.registers_IDEX.out_instr_type);

            $display("\n========================================\n");
            // Execute Stage
            $display("EXECUTE: alu_out=%h out_mem_in_data=%h out_PC=%h out_branch_taken=%b out_branch_inst=%b out_rd=%d out_mem_write=%b out_mem_read=%b out_mem_to_reg=%b out_write_enable=%b out_branch_inst=%b\n",
                dut.execute.out_alu_out,
                dut.execute.out_mem_in_data,
                dut.execute.out_PC,
                dut.execute.out_branch_taken,
                dut.execute.out_branch_inst,
                dut.execute.out_rd,
                dut.execute.out_mem_write,
                dut.execute.out_mem_read,
                dut.execute.out_mem_to_reg,
                dut.execute.out_write_enable,
                dut.execute.out_branch_inst);

            // Execute to Memory registers
            $display("Registers EXMEM: new_PC=%h branch_taken=%b branch_inst=%b out_alu_out=%h out_mem_data=%h mem_write=%b mem_read=%b rd=%d mem_to_reg=%b write_enable=%b\n",
                dut.registers_EXMEM.out_new_PC,
                dut.registers_EXMEM.out_branch_taken,
                dut.registers_EXMEM.out_branch_inst,
                dut.registers_EXMEM.out_alu_out,
                dut.registers_EXMEM.out_mem_data,
                dut.registers_EXMEM.out_mem_write,
                dut.registers_EXMEM.out_mem_read,
                dut.registers_EXMEM.out_rd,
                dut.registers_EXMEM.out_mem_to_reg,
                dut.registers_EXMEM.out_write_enable);

            $display("\n========================================\n");
            // Memory Stage
            $display("MEMORY: out_alu_out=%h out_mem_out=%h out_rd=%d out_mem_to_reg=%b out_write_enable=%b\n",
                dut.dmemory.out_alu_out,
                dut.dmemory.out_mem_out,
                dut.dmemory.out_rd,
                dut.dmemory.out_mem_to_reg,
                dut.dmemory.out_write_enable);

            // Memory to Writeback registers
            $display("Registers MEMWB: out_alu_out=%h out_mem_out=%h out_rd=%d out_mem_to_reg=%b out_write_enable=%b\n",
                dut.registers_MEMWB.out_alu_out,
                dut.registers_MEMWB.out_mem_out,
                dut.registers_MEMWB.out_rd,
                dut.registers_MEMWB.out_mem_to_reg,
                dut.registers_MEMWB.out_write_enable);

            $display("\n========================================\n");
            // Writeback Stage
            $display("WRITEBACK: out_rd=%d out_data=%h out_write_enable=%b",
                dut.writeback.out_rd,
                dut.writeback.out_data,
                dut.writeback.out_write_enable);

            // Register File Status
            $display("REGISTERS: r0=%h r1=%h r2=%h r3=%h",
                dut.decode.RF.registers[0],
                dut.decode.RF.registers[1],
                dut.decode.RF.registers[2],
                dut.decode.RF.registers[3]);
            $display("          r4=%h r5=%h r6=%h r7=%h r8=%h",
                dut.decode.RF.registers[4],
                dut.decode.RF.registers[5],
                dut.decode.RF.registers[6],
                dut.decode.RF.registers[7],
                dut.decode.RF.registers[8]);

            $display("\n\n\n");
            $fflush();  // Force output to display immediately
        end
    end

    // Dump waves
    initial begin
        $dumpfile("core_testbench.vcd");
        $dumpvars(0, core_testbench);
    end

endmodule
