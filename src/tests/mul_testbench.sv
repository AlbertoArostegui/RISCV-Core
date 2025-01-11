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
        $dumpfile("mul_testbench.vcd");
        $dumpvars(0, soc_testbench);
        $dumpvars(0, dut);

        $readmemh("/Users/alberto/pa/src/tests/hex/mul.hex", dut.memory.memory, 32'h14, 32'h16);
        /*
        addi x3, x0, 50
        addi x2, x0, 50
        mul x1, x2, x3
        */

        $display("At 0x1000: %h", dut.memory.memory[32'h400]);
        for(int i = 32'h800; i <= 32'h802; i = i+1) begin
            $display("%h", dut.memory.memory[i]);
        end

        reset = 1;
        #2 reset = 0;

        repeat(1000) begin
            #2;
            display_processor_state();
        end
        $finish;
    end
    task automatic display_processor_state;
        $display("\n╔═══════════════════ CYCLE %0d ════════════════════╗", $time/2);

        $display("\n[🔐 PRIVILEGED REGISTERS]");
        $display("IN: write_enable=%b rm_idx=%d write_data=%h", dut.core.fetch.privileged_regs.in_write_enable, dut.core.fetch.privileged_regs.in_rm_idx, dut.core.fetch.privileged_regs.in_write_data);
        $display("Current Mode: %s", dut.core.fetch.privileged_regs.out_supervisor_mode ? "Supervisor" : "User");
        $display("rm0 (fault PC): %h", dut.core.fetch.privileged_regs.rm[0]);
        $display("rm1 (fault addr): %h", dut.core.fetch.privileged_regs.rm[1]);
        $display("rm2 (additional): %h", dut.core.fetch.privileged_regs.rm[2]);
        $display("rm4 (status): %h", dut.core.fetch.privileged_regs.rm[4]);

        $display("out_overwrite_PC=%b out_new_address=%h", dut.core.fetch.privileged_regs.out_overwrite_PC, dut.core.fetch.privileged_regs.out_new_address);
        
        $display("\n[📋 REORDER BUFFER STATE]");
        $display("INPUTS:");
        $display("  Allocate=%b in_PC=%h rd=%d instr_type=%b\n     stall=%b (IFID_to_ROB_wait_stall = %b | d_cache_stall = %b)", 
            dut.core.rob.in_allocate,
            dut.core.rob.in_PC,
            dut.core.rob.in_rd,
            dut.core.rob.in_instr_type,
            dut.core.rob.in_stall,
            dut.core.IFID_to_ROB_wait_stall,
            dut.core.d_cache_stall
        );
        $display("  Execute complete=%b idx=%d value=%h exception=%3b",
            dut.core.rob.in_complete,
            dut.core.rob.in_complete_idx,
            dut.core.rob.in_complete_value,
            dut.core.rob.in_exception_vector
        );
        $display("  Cache complete=%b idx=%d value=%h exception=%b",
            dut.core.rob.in_cache_complete,
            dut.core.rob.in_cache_complete_idx,
            dut.core.rob.in_cache_out,
            dut.core.rob.in_cache_exception
        );
        $display("  Mul complete=%b idx=%d value=%h exception=%3b",
            dut.core.rob.in_mul_complete,
            dut.core.rob.in_mul_complete_idx,
            dut.core.rob.in_mul_complete_value,
            dut.core.rob.in_mul_exception
        );
        
        $display("\nOUTPUTS:");
        $display("  Ready=%b value=%h rd=%d exception=%3b instr_type=%b out_full=%b\nrs1_bypass=%b rs1_bypass_value=%h rs2_bypass=%b rs2_bypass_value=%h\n(For SB) out_complete_idx=%d\nPrivileged write enable=%b Privileged rm idx=%d",
            dut.core.rob.out_ready,
            dut.core.rob.out_value,
            dut.core.rob.out_rd,
            dut.core.rob.out_exception_vector,
            dut.core.rob.out_instr_type,
            dut.core.rob.out_full,
            dut.core.rob.out_rs1_bypass,
            dut.core.rob.out_rs1_bypass_value,
            dut.core.rob.out_rs2_bypass,
            dut.core.rob.out_rs2_bypass_value,
            dut.core.rob.out_complete_idx,
            dut.core.rob.out_priv_write_enable,
            dut.core.rob.out_priv_rm_idx
        );
        $display("Full=%b alloc_idx=%d",
            dut.core.rob.out_full,
            dut.core.rob.out_alloc_idx
        );
        
        $display("\nROB ENTRIES (head=%d in_allocate_idx=%d count=%d):", 
            dut.core.rob.head,
            dut.core.rob.in_allocate_idx,
            dut.core.rob.count
        );
        $display("╔════╤══════════╤══════════╤═════╤═══════╤═════════╤═════════════╤════════════╗");
        $display("║ ## │    PC    │  VALUE   │ RD  │ VALID │COMPLETE │  EXCEPTION  │ INSTR_TYPE ║");
        $display("╠════╪══════════╪══════════╪═════╪═══════╪═════════╪═════════════╪════════════╣");
        for(int i = 0; i < 10; i++) begin
            $display("║ %2d │ %6h │ %6h │ %3d │   %b   │    %b    │     %b     │    %b     ║",
                i,
                dut.core.rob.PC[i],
                dut.core.rob.value[i],
                dut.core.rob.rd[i],
                dut.core.rob.valid[i],
                dut.core.rob.complete[i],
                dut.core.rob.exception[i],
                dut.core.rob.instr_type[i]
            );
        end
        $display("╚════╧══════════╧══════════╧═════╧═══════╧═════════╧═════════════╧════════════╝");

        // FETCH STAGE
        $display("\n[📍 FETCH STAGE]");
        $display("IN:");
        $display("  branch_taken=%b next_PC=%h pc_write_disable=%b", 
            dut.core.fetch.branch_taken,
            dut.core.fetch.next_pc,
            dut.core.fetch.pc_write_disable
        );

        $display("PC: %h", dut.core.fetch.PC);

        // TLB STATE 
        $display("\n[📖 INSTRUCTION TLB STATE]");
        $display("╔════╤═══════════╤════════════╤═══════╗");
        $display("║ ## │ Virtual @ │ Physical @ │ Valid ║");
        $display("╠════╪═══════════╪════════════╪═══════╣");
        for(int i = 0; i < 4; i++) begin
            $display("║ %2d │     %h │      %h │   %b   ║",
                i,
                dut.core.fetch.itlb.v_addr[i],
                dut.core.fetch.itlb.p_addr[i],
                dut.core.fetch.itlb.valid[i]
            );
        end
        $display("╚════╧═══════════╧════════════╧═══════╝");
        $display("INPUTS: in_write_enable= %b in_write_virtual_address= %h in_write_physical_address= %h", 
            dut.core.fetch.itlb.in_write_enable,
            dut.core.fetch.itlb.in_write_virtual_address,
            dut.core.fetch.itlb.in_write_physical_address
        );
        $display("TLB OUT: out_physical_address=%h out_tlb_hit=%b",
            dut.core.fetch.itlb.out_physical_address,
            dut.core.fetch.itlb.out_tlb_hit
        );

        // INSTRUCTION CACHE STATE
        $display("\n[💻 INSTRUCTION CACHE STATE]");
        $display("INPUTS:");
        $display("  Address: %h", dut.core.fetch.icache.in_addr);
        $display("  TLB Hit: %b", dut.core.fetch.icache.in_tlb_hit);
        $display("  Read/Write: %b/%b", dut.core.fetch.icache.in_read_en, dut.core.fetch.icache.in_write_en);
        
        $display("\nSTATE:");
        $display("╔════╤════╤══════════════╤══════════════════════════════════╤═══════╤═══════╗");
        $display("║ Set│ Way│     Tag      │              Data                │ Valid │ Dirty ║");
        $display("╠════╪════╪══════════════╪══════════════════════════════════╪═══════╪═══════╣");
        for(int i = 0; i < 2; i++) begin
            for(int j = 0; j < 2; j++) begin
                $display("║ %2d │ %2d │      %h │ %32h │   %b   │   %b   ║",
                    i, j,
                    dut.core.fetch.icache.tags[i][j],
                    dut.core.fetch.icache.data[i][j],
                    dut.core.fetch.icache.valid[i][j],
                    dut.core.fetch.icache.dirty[i][j]
                );
            end
            if (i == 0) $display("╟────┼────┼──────────────┼──────────────────────────────────┼───────┼───────╢");
        end
        $display("╚════╧════╧══════════════╧══════════════════════════════════╧═══════╧═══════╝");
        $display("LRU: Set0=%b Set1=%b", dut.core.fetch.icache.lru[0], dut.core.fetch.icache.lru[1]);
        
        $display("\nOUTPUTS:");
        $display("  Data Out: %h", dut.core.fetch.icache.out_read_data);
        $display("  Hit: %b  Busy: %b", dut.core.fetch.icache.out_hit, dut.core.fetch.icache.out_busy);
        $display("  Memory Interface: addr=%h read=%b write=%b",
            dut.core.fetch.icache.out_mem_addr,
            dut.core.fetch.icache.out_mem_read_en,
            dut.core.fetch.icache.out_mem_write_en
        );
        
        $display("OUT:");
        $display("  PC=%h instruction=%h (%s)\n exception_vector=%3b", 
            dut.core.fetch.out_PC,
            dut.core.fetch.out_instruction,
            decode_instruction(dut.core.fetch.out_instruction),
            dut.core.fetch.out_exception_vector
        );

        $display("\n[rob_idx reg = %d]", dut.core.rob_idx);
        // IF/ID Pipeline Registers
        $display("\n[🔄 IF/ID REGISTERS]");
        $display("IN: IFID_write_disable=%b in_rob_idx=%d", dut.core.registers_IFID.in_complete_idx, dut.core.registers_IFID.in_IFID_write_disable);
        $display("OUT: PC=%h instruction=%h (%s)\n     ROB_IDX = %d",
            dut.core.registers_IFID.out_PC,
            dut.core.registers_IFID.out_instruction,
            decode_instruction(dut.core.registers_IFID.out_instruction),
            dut.core.registers_IFID.out_complete_idx
        );
        $display(" Control: exception=%3b", dut.core.registers_IFID.out_exception_vector);

        // DECODE STAGE
        $display("\n[🔍 DECODE STAGE]");
        $display("IN:");
        $display("  Instruction=%h (%s) PC=%h",
            dut.core.decode.in_instruction,
            decode_instruction(dut.core.decode.in_instruction),
            dut.core.decode.in_PC
        );
        $display("  Register File Write: enable=%b reg=%d data=%h",
            dut.core.decode.in_write_enable,
            dut.core.decode.in_write_reg,
            dut.core.decode.in_write_data
        );
        $display("  Hazard Detection: rs1=%d rs2=%d IDEX_rd=%d IDEX_mem_read=%b",
            dut.core.decode.hazard_detection_unit.in_IFID_rs1,
            dut.core.decode.hazard_detection_unit.in_IFID_rs2,
            dut.core.decode.in_IDEX_rd,
            dut.core.decode.in_IDEX_mem_read
        );
        $display("OUT:");
        $display("  Decoded: rs1=%d rs2=%d rd=%d data_rs1=%h data_rs2=%h imm=%h",
            dut.core.decode.out_rs1,
            dut.core.decode.out_rs2,
            dut.core.decode.out_rd,
            dut.core.decode.out_data_a,
            dut.core.decode.out_data_b,
            dut.core.decode.out_immediate
        );
        $display("  Control: alu_src=%b alu_op=%b mem_write=%b mem_read=%b branch=%b memToReg=%b regWrite=%b exception=%3b",
            dut.core.decode.EX_alu_src,
            dut.core.decode.EX_alu_op,
            dut.core.decode.MEM_mem_write,
            dut.core.decode.MEM_mem_read,
            dut.core.decode.MEM_branch_inst,
            dut.core.decode.WB_write_mem_to_reg,
            dut.core.decode.WB_write_enable,
            dut.core.decode.out_exception_vector
        );
        $display("  Hazard: pc_stall=%b IFID_stall=%b",
            dut.core.decode.out_pc_write_disable,
            dut.core.decode.out_IFID_write_disable
        );

        // ID/EX Pipeline Registers
        $display("\n[🔄 ID/EX REGISTERS]");
        $display("OUT: PC=%h instruction=%h (%s)\n     ROB_IDX = %d",
            dut.core.registers_IDEX.out_PC,
            dut.core.registers_IDEX.out_instruction,
            decode_instruction(dut.core.registers_IDEX.out_instruction),
            dut.core.registers_IDEX.out_complete_idx
        );
        $display("  Data: rs1=%d rs2=%d rd=%d data_rs1=%h data_rs2=%h imm=%h",
            dut.core.registers_IDEX.out_rs1,
            dut.core.registers_IDEX.out_rs2,
            dut.core.registers_IDEX.out_rd,
            dut.core.registers_IDEX.out_data_rs1,
            dut.core.registers_IDEX.out_data_rs2,
            dut.core.registers_IDEX.out_immediate
        );
        $display("  Control: alu_src=%b alu_op=%b mem_write=%b mem_read=%b branch=%b memToReg=%b regWrite=%b exception=%3b",
            dut.core.registers_IDEX.out_alu_src,
            dut.core.registers_IDEX.out_alu_op,
            dut.core.registers_IDEX.out_mem_write,
            dut.core.registers_IDEX.out_mem_read,
            dut.core.registers_IDEX.out_branch_inst,
            dut.core.registers_IDEX.out_mem_to_reg,
            dut.core.registers_IDEX.out_write_enable,
            dut.core.registers_IDEX.out_exception_vector
        );

        // EXECUTE STAGE
        $display("\n[⚡ EXECUTE STAGE]");
        $display("IN:");
        $display("  Data: PC=%h rs1_data=%h rs2_data=%h imm=%h", 
            dut.core.execute.in_PC,
            dut.core.execute.in_data_rs1,
            dut.core.execute.in_data_rs2,
            dut.core.execute.in_immediate
        );
        
        // Forwarding logic breakdown
        $display("\nFORWARDING RESOLUTION:");
        $display("Operand 1 (rs1=%d):", dut.core.execute.in_rs1);
        $display("  REG   value: %h", dut.core.execute.in_data_rs1);
        $display("  EXMEM value: %h", dut.core.execute.in_EXMEM_alu_out);
        $display("  MEMWB value: %h", dut.core.execute.in_MEMWB_out_data);
        $display("  ROB   value: %h", dut.core.execute.in_rs1_ROB_bypass_value);
        $display("  Selected: %h (%s)", 
            dut.core.execute.alu_operand1,
            decode_forward(dut.core.execute.forwarding_unit.forwardA, dut.core.execute.in_rs1_ROB_bypass)
        );

        $display("\nOperand 2 (rs2=%d):", dut.core.execute.in_rs2);
        $display("  REG   value: %h", dut.core.execute.in_data_rs2);
        $display("  EXMEM value: %h", dut.core.execute.in_EXMEM_alu_out);
        $display("  MEMWB value: %h", dut.core.execute.in_MEMWB_out_data);
        $display("  ROB   value: %h", dut.core.execute.in_rs2_ROB_bypass_value);
        $display("  Selected: %h (%s)", 
            dut.core.execute.alu_operand2,
            decode_forward(dut.core.execute.forwarding_unit.forwardB, dut.core.execute.in_rs2_ROB_bypass)
        );
        $display("OUT:");
        $display("  ALU: result=%h branch_taken=%b\n exception_vector=%3b",
            dut.core.execute.out_alu_out,
            dut.core.execute.out_branch_taken,
            dut.core.execute.out_exception_vector
        );
        $display("  Forward: A=%b B=%b",
            dut.core.execute.forwarding_unit.forwardA,
            dut.core.execute.forwarding_unit.forwardB
        );
        $display(" out_itlb_write_enable=%b out_dtlb_write_enable=%b\nout_tlb_virtual_address=%h out_tlb_physical_address=%h",
            dut.core.execute.out_itlb_write_enable,
            dut.core.execute.out_dtlb_write_enable,
            dut.core.execute.out_tlb_virtual_address,
            dut.core.execute.out_tlb_physical_address
        );

        // EX/MEM Pipeline Registers
        $display("\n[🔄 EX/MEM REGISTERS]");
        $display("OUT: alu_out=%h mem_data=%h rd=%d exception_vector=%3b",
            dut.core.registers_EXMEM.out_alu_out,
            dut.core.registers_EXMEM.out_mem_data,
            dut.core.registers_EXMEM.out_rd,
            dut.core.registers_EXMEM.out_exception_vector
        );
        $display("  Control: mem_write=%b mem_read=%b memToReg=%b regWrite=%b",
            dut.core.registers_EXMEM.out_mem_write,
            dut.core.registers_EXMEM.out_mem_read,
            dut.core.registers_EXMEM.out_mem_to_reg,
            dut.core.registers_EXMEM.out_write_enable
        );

        // MEMORY STAGE
        $display("\n[💾 CACHE STAGE]");
        $display("IN: addr=%h write_data=%h write=%b read=%b",
            dut.core.cache.in_alu_out,
            dut.core.cache.in_write_data,
            dut.core.cache.in_write_en,
            dut.core.cache.in_read_en
        );
        $display("OUT: mem_data=%h alu_out=%h rd=%d",
            dut.core.cache.out_read_data,
            dut.core.cache.out_alu_out,
            dut.core.cache.out_rd
        );

        $display("\n[📦 STORE BUFFER STATE]");
        $display("ROB INPUTS: in_rob_idx=%d in_complete=%b in_complete_idx=%d in_exception_vector=%3b",
            dut.core.cache.store_buffer.in_rob_idx,
            dut.core.cache.store_buffer.in_complete,
            dut.core.cache.store_buffer.in_complete_idx,
            dut.core.cache.store_buffer.in_exception_vector
        );
        $display("COUNTERS:");
        $display("  Stores: %d  Oldest: %d", 
            dut.core.cache.store_buffer.store_counter, 
            dut.core.cache.store_buffer.oldest
        );
        $display("STATUS:");
        $display("  Hit: %b  Stall: %b", 
            dut.core.cache.store_buffer.out_hit, 
            dut.core.cache.store_buffer.out_stall
        );
        
        $display("\nENTRIES:");
        $display("╔════╤════════════╤════════════╤══════════╤══════════╤═══════╗");
        $display("║ ## │   Address  │    Data    │  Funct3  │ ROB Idx  │ Valid ║");
        $display("╠════╪════════════╪════════════╪══════════╪══════════╪═══════╣");
        for(int i = 0; i < 4; i++) begin
            $display("║ %2d │   %h │   %h │    %3b   │    %2d    │   %b   ║",
                i,
                dut.core.cache.store_buffer.addr[i],
                dut.core.cache.store_buffer.data[i],
                dut.core.cache.store_buffer.funct3[i],
                dut.core.cache.store_buffer.rob_idx[i],
                dut.core.cache.store_buffer.valid[i]
            );
            if (i < 3) $display("╟────┼────────────┼────────────┼──────────┼──────────┼───────╢");
        end
        $display("╚════╧════════════╧════════════╧══════════╧══════════╧═══════╝");
        $display("OUTPUTS: out_addr=%h out_data=%h out_funct3=%3b out_write_to_cache=%b\nout_hit=%b out_stall=%b",
            dut.core.cache.store_buffer.out_addr,
            dut.core.cache.store_buffer.out_data,
            dut.core.cache.store_buffer.out_funct3,
            dut.core.cache.store_buffer.out_write_to_cache,
            dut.core.cache.store_buffer.out_hit,
            dut.core.cache.store_buffer.out_stall
        );

        // DATA TLB STATE 
        $display("\n[📖 DATA TLB STATE]");
        $display("╔════╤═══════════╤════════════╤═══════╗");
        $display("║ ## │ Virtual @ │ Physical @ │ Valid ║");
        $display("╠════╪═══════════╪════════════╪═══════╣");
        for(int i = 0; i < 4; i++) begin
            $display("║ %2d │     %h │      %h │   %b   ║",
                i,
                dut.core.cache.dtlb.v_addr[i],
                dut.core.cache.dtlb.p_addr[i],
                dut.core.cache.dtlb.valid[i]
            );
        end
        $display("╚════╧═══════════╧════════════╧═══════╝");
        $display("TLB OUT: out_physical_address=%h out_tlb_hit=%b",
            dut.core.cache.dtlb.out_physical_address,
            dut.core.cache.dtlb.out_tlb_hit
        );

        // DATA CACHE STATE
        $display("\n[💾 DATA CACHE STATE]");
        $display("INPUTS:");
        $display("  Address: %h", dut.core.cache.d_cache.in_addr);
        $display("  Write Data: %h", dut.core.cache.d_cache.in_write_data);
        $display("  Read/Write: %b/%b", dut.core.cache.d_cache.in_read_en, dut.core.cache.d_cache.in_write_en);
        $display("  Function3: %b", dut.core.cache.d_cache.in_funct3);
        
        $display("\nSTATE:");
        $display("╔════╤════╤════════════╤══════════════════════════════════╤═══════╤═══════╗");
        $display("║Set │Way │    Tag     │              Data                │ Valid │ Dirty ║");
        $display("╠════╪════╪════════════╪══════════════════════════════════╪═══════╪═══════╣");
        for(int i = 0; i < 2; i++) begin
            for(int j = 0; j < 2; j++) begin
                $display("║ %2d │ %2d │    %h │ %32h │   %b   │   %b   ║",
                    i, j,
                    dut.core.cache.d_cache.tags[i][j],
                    dut.core.cache.d_cache.data[i][j],
                    dut.core.cache.d_cache.valid[i][j],
                    dut.core.cache.d_cache.dirty[i][j]
                );
            end
            if (i == 0) $display("╟────┼────┼────────────┼──────────────────────────────────┼───────┼───────╢");
        end
        $display("╚════╧════╧════════════╧══════════════════════════════════╧═══════╧═══════╝");
        $display("LRU: Set0=%b Set1=%b", dut.core.cache.d_cache.lru[0], dut.core.cache.d_cache.lru[1]);
        
        $display("\nOUTPUTS:");
        $display("  Data Out: %h", dut.core.cache.d_cache.out_read_data);
        $display("  Hit: %b  Busy: %b", dut.core.cache.d_cache.out_hit, dut.core.cache.d_cache.out_busy);
        $display("  Memory Interface: addr=%h read=%b write=%b",
            dut.core.cache.d_cache.out_mem_addr,
            dut.core.cache.d_cache.out_mem_read_en,
            dut.core.cache.d_cache.out_mem_write_en
        );

        // MEM/WB Pipeline Registers
        $display("\n[🔄 MEM/WB REGISTERS]");
        $display("OUT: alu_out=%h mem_out=%h rd=%d memToReg=%b regWrite=%b",
            dut.core.registers_MEMWB.out_alu_out,
            dut.core.registers_MEMWB.out_mem_out,
            dut.core.registers_MEMWB.out_rd,
            dut.core.registers_MEMWB.out_mem_to_reg,
            dut.core.registers_MEMWB.out_write_enable
        );

        // M3/M4 Pipeline Registers
        $display("\n[🔄 M3/M4 REGISTERS]");
        $display("OUT: mul_out=%h rob_idx=%d exception=%b instr_type=%b",
            dut.core.registers_M3M4.out_mul_out,
            dut.core.registers_M3M4.out_rob_idx,
            dut.core.registers_M3M4.out_exception_vector,
            dut.core.registers_M3M4.out_instr_type
        );

        // M4/M5 Pipeline Registers
        $display("\n[🔄 M4/M5 REGISTERS]");
        $display("OUT: mul_out=%h rob_idx=%d exception=%b instr_type=%b",
            dut.core.registers_M4M5.out_mul_out,
            dut.core.registers_M4M5.out_rob_idx,
            dut.core.registers_M4M5.out_exception_vector,
            dut.core.registers_M4M5.out_instr_type
        );

        // Add after Memory Stage and before MEM/WB Registers:

        // MULTIPLY STAGE
        $display("\n[✖️ MULTIPLY STAGE]");
        $display("IN: mul_out=%h rob_idx=%d exception=%b instr_type=%b",
            dut.core.stage_multiply.in_mul_out,
            dut.core.stage_multiply.in_rob_idx,
            dut.core.stage_multiply.in_exception_vector,
            dut.core.stage_multiply.in_instr_type
        );
        $display("OUT: result=%h rob_idx=%d complete=%b exception=%b",
            dut.core.stage_multiply.out_mul_out,
            dut.core.stage_multiply.out_rob_idx,
            dut.core.stage_multiply.out_complete,
            dut.core.stage_multiply.out_exception_vector
        );

        // M5/WB Pipeline Registers
        $display("\n[🔄 M5/WB REGISTERS]");
        $display("OUT: mul_out=%h rob_idx=%d complete=%b exception=%b",
            dut.core.M5WB_to_ROB_complete_value,
            dut.core.M5WB_to_ROB_complete_idx,
            dut.core.M5WB_to_ROB_complete,
            dut.core.M5WB_to_ROB_exception_vector
        );

        // Register File State
        $display("\n[📊 REGISTER FILE STATE]");
        for(int i = 0; i < 32; i += 4) begin
            $display("x%-2d: %8h | x%-2d: %8h | x%-2d: %8h | x%-2d: %8h",
                i, dut.core.decode.RF.registers[i],
                i+1, dut.core.decode.RF.registers[i+1],
                i+2, dut.core.decode.RF.registers[i+2],
                i+3, dut.core.decode.RF.registers[i+3]
            );
        end

        // Memory Contents
        $display("\n[📝 MEMORY CONTENTS] (First 32 words)");
        for(int i = 0; i < 32; i += 4) begin
            $display("%3h: %8h %8h %8h %8h",
                i, dut.memory.memory[i],
                dut.memory.memory[i+1],
                dut.memory.memory[i+2],
                dut.memory.memory[i+3]
            );
        end

        $display("\n════════════════════════════════════════════════════════════════\n");
    endtask 

    // Helper function to decode instructions into assembly
    function string decode_instruction(input logic [31:0] instruction);
        logic [6:0] opcode;
        logic [4:0] rd, rs1, rs2;
        logic [2:0] funct3;
        logic [6:0] funct7;
        logic [11:0] imm_i;
        logic [11:0] imm_s;
        logic [12:0] imm_b;
        string asm;

        opcode = instruction[6:0];
        rd = instruction[11:7];
        rs1 = instruction[19:15];
        rs2 = instruction[24:20];
        funct3 = instruction[14:12];
        funct7 = instruction[31:25];
        imm_i = instruction[31:20];
        imm_s = {instruction[31:25], instruction[11:7]};
        imm_b = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};

        case (opcode)
            7'b0110011: begin // R-type
                case ({funct7, funct3})
                    10'b0000000000: asm = $sformatf("add x%0d,x%0d,x%0d", rd, rs1, rs2);
                    10'b0100000000: asm = $sformatf("sub x%0d,x%0d,x%0d", rd, rs1, rs2);
                    10'b0000001000: asm = $sformatf("mul x%0d,x%0d,x%0d", rd, rs1, rs2);
                default: asm = "unknown-R";
            endcase
            end
            7'b1110011: begin // System instructions
                case (funct3)
                    3'b000: asm = "iret";                                     // IRET
                    3'b010: asm = $sformatf("tlbwrite x%0d,x%0d", rs1, rs2);  // TLBWRITE
                    3'b001: asm = $sformatf("movrm x%0d,rm%0d", rd, rs1);     // MOVRM
                    default: asm = "unknown-system";
                endcase
            end
            7'b0010011: asm = $sformatf("addi x%0d,x%0d,%0d", rd, rs1, $signed(imm_i));
            7'b1100011: begin // B-type
                case (funct3)
                    3'b001: asm = $sformatf("bne x%0d,x%0d,%0d", rs1, rs2, $signed(imm_b));
                    3'b000: asm = $sformatf("beq x%0d,x%0d,%0d", rs1, rs2, $signed(imm_b));
                    default: asm = "unknown-B";
                endcase
            end
            7'b0000011: begin // Load instructions
                case (funct3)
                    3'b010: asm = $sformatf("lw x%0d,%0d(x%0d)", rd, $signed(imm_i), rs1); // lw
                    3'b001: asm = $sformatf("lh x%0d,%0d(x%0d)", rd, $signed(imm_i), rs1); // lh
                    3'b000: asm = $sformatf("lb x%0d,%0d(x%0d)", rd, $signed(imm_i), rs1); // lb
                    default: asm = "unknown-load";
                endcase
            end
            7'b0100011: begin // Store instructions
                case (funct3)
                    3'b010: asm = $sformatf("sw x%0d,%0d(x%0d)", rs2, $signed(imm_s), rs1); // sw
                    3'b001: asm = $sformatf("sh x%0d,%0d(x%0d)", rs2, $signed(imm_s), rs1); // sh
                    3'b000: asm = $sformatf("sb x%0d,%0d(x%0d)", rs2, $signed(imm_s), rs1); // sb
                    default: asm = "unknown-store";
                endcase
            end
            7'b0001000: begin
                case (funct3)
                    3'b000: asm = $sformatf("itlbwrite x%0d, x%0d", rs1, rs2);
                    3'b001: asm = $sformatf("dtlbwrite x%0d, x%0d", rs1, rs2);
                    default: asm = "unknown-tlbwrite";
                endcase
            end
            default: asm = instruction == 32'h00000013 ? "nop" : "unknown";
        endcase
        return asm;
    endfunction

    function string decode_forward(input logic [1:0] forward, input logic rob_bypass);
    case ({forward, rob_bypass})
        3'b100: return "EXMEM";
        3'b010: return "MEMWB";
        3'b001: return "ROB";
        default: return "REG";
    endcase
    endfunction

    function string decode_exception;
        input [2:0] exception_vector;
        begin
            case(exception_vector)
                3'b001: return "TLB Miss";
                3'b010: return "Illegal Instruction";
                3'b100: return "Privilege Violation";
                default: return "No Exception";
            endcase
        end
    endfunction
endmodule