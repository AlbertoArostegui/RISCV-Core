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
        $dumpfile("first_perf_testbench.vcd");
        $dumpvars(0, soc_testbench);
        $dumpvars(0, dut);

        $readmemh("/Users/alberto/pa/src/tests/hex/first_perf.hex", dut.memory.memory, 32'h80, 32'h89);
        /*
            addi    x11, x0, 0       # sum = 0 (x11 holds sum)
            addi    x12, x0, 0       # i = 0 (x12 holds i)
            addi    x13, x0, 128     # Load loop limit 128 into x13

        loop:
            bge     x12, x13, end    # if (i >= 128) break
            slli    x14, x12, 2      # x14 = i * 4 (byte offset, 4 bytes per int)
            add     x15, x10, x14    # x15 = &a[i] (base address + offset)
            lw      x16, 0(x15)      # x16 = a[i] (load word from memory)
            add     x11, x11, x16    # sum += a[i]
            addi    x12, x12, 1      # i++
            j       loop             # Repeat the loop

        end:
        */

        for(int i = 32'h80; i < 32'h8a; i = i+1) begin
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
        
        $display("\n[📋 REORDER BUFFER STATE]");
        $display("INPUTS:");
        $display("  Allocate=%b in_PC=%h rd=%d instr_type=%b\n     stall=%b", 
            dut.core.rob.in_allocate,
            dut.core.rob.in_PC,
            dut.core.rob.in_rd,
            dut.core.rob.in_instr_type,
            dut.core.rob.in_stall
        );
        $display("  Execute complete=%b idx=%d value=%h exception=%b",
            dut.core.rob.in_complete,
            dut.core.rob.in_complete_idx,
            dut.core.rob.in_complete_value,
            dut.core.rob.in_exception
        );
        $display("  Cache complete=%b idx=%d value=%h exception=%b",
            dut.core.rob.in_cache_complete,
            dut.core.rob.in_cache_complete_idx,
            dut.core.rob.in_cache_out,
            dut.core.rob.in_cache_exception
        );
        $display("  Mul complete=%b idx=%d value=%h exception=%b",
            dut.core.rob.in_mul_complete,
            dut.core.rob.in_mul_complete_idx,
            dut.core.rob.in_mul_complete_value,
            dut.core.rob.in_mul_exception
        );
        
        $display("\nOUTPUTS:");
        $display("  Ready=%b value=%h rd=%d exception=%b instr_type=%b out_full=%b\nrs1_bypass=%b rs1_bypass_value=%h rs2_bypass=%b rs2_bypass_value=%h",
            dut.core.rob.out_ready,
            dut.core.rob.out_value,
            dut.core.rob.out_rd,
            dut.core.rob.out_exception,
            dut.core.rob.out_instr_type,
            dut.core.rob.out_full,
            dut.core.rob.out_rs1_bypass,
            dut.core.rob.out_rs1_bypass_value,
            dut.core.rob.out_rs2_bypass,
            dut.core.rob.out_rs2_bypass_value
        );
        $display("  Full=%b alloc_idx=%d",
            dut.core.rob.out_full,
            dut.core.rob.out_alloc_idx
        );
        
        $display("\nROB ENTRIES (head=%d in_allocate_idx=%d count=%d):", 
            dut.core.rob.head,
            //dut.core.rob.tail,
            dut.core.rob.in_allocate_idx,
            dut.core.rob.count
        );
        $display("╔════╤══════════╤══════════╤═════╤═══════╤═════════╤═════════════╤════════════╗");
        $display("║ ## │    PC    │  VALUE   │ RD  │ VALID │COMPLETE │  EXCEPTION  │ INST_TYPE  ║");
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
        $display("  branch_taken=%b new_PC=%h pc_write_disable=%b", 
            dut.core.fetch.branch_taken,
            dut.core.fetch.new_pc,
            dut.core.fetch.pc_write_disable
        );
        $display("OUT:");
        $display("  PC=%h instruction=%h (%s)", 
            dut.core.fetch.out_PC,
            dut.core.fetch.out_instruction,
            decode_instruction(dut.core.fetch.out_instruction)
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
        $display("  Control: alu_src=%b alu_op=%b mem_write=%b mem_read=%b branch=%b memToReg=%b regWrite=%b",
            dut.core.decode.EX_alu_src,
            dut.core.decode.EX_alu_op,
            dut.core.decode.MEM_mem_write,
            dut.core.decode.MEM_mem_read,
            dut.core.decode.MEM_branch_inst,
            dut.core.decode.WB_write_mem_to_reg,
            dut.core.decode.WB_write_enable
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
        $display("  Control: alu_src=%b alu_op=%b mem_write=%b mem_read=%b branch=%b memToReg=%b regWrite=%b",
            dut.core.registers_IDEX.out_alu_src,
            dut.core.registers_IDEX.out_alu_op,
            dut.core.registers_IDEX.out_mem_write,
            dut.core.registers_IDEX.out_mem_read,
            dut.core.registers_IDEX.out_branch_inst,
            dut.core.registers_IDEX.out_mem_to_reg,
            dut.core.registers_IDEX.out_write_enable
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
        $display("  ALU: result=%h branch_taken=%b",
            dut.core.execute.out_alu_out,
            dut.core.execute.out_branch_taken
        );
        $display("  Forward: A=%b B=%b",
            dut.core.execute.forwarding_unit.forwardA,
            dut.core.execute.forwarding_unit.forwardB
        );

        // EX/MEM Pipeline Registers
        $display("\n[🔄 EX/MEM REGISTERS]");
        $display("OUT: alu_out=%h mem_data=%h rd=%d",
            dut.core.registers_EXMEM.out_alu_out,
            dut.core.registers_EXMEM.out_mem_data,
            dut.core.registers_EXMEM.out_rd
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

        // Cache internals
        $display("\nCache Internals:\n")
        $display("Full address: 0x%b", {dut.core.cache.d_cache.tag, dut.core.cache.d_cache.set_index, dut.core.cache.d_cache.word_offset, dut.core.cache.d_cache.byte_offset});
        $display("Set Index: %b", dut.core.cache.d_cache.set_index);
        $display("Tag: 0x%b", dut.core.cache.d_cache.tag);
        $display("Word Offset: %b", dut.core.cache.d_cache.word_offset);
        $display("Byte Offset: %b", dut.core.cache.d_cache.byte_offset);

        for (int i = 0; i < 2; i++) begin
            for (int j = 0; j < 2; j++) begin
                $display("  Set %0d Way %0d:", i, j);
                $display("    Valid: %b", dut.core.cache.d_cache.valid[i][j]);
                $display("    Dirty: %b", dut.core.cache.d_cache.dirty[i][j]);
                $display("    Tag: 0x%b", dut.core.cache.d_cache.tags[i][j]);
                $display("    Data: 0x%h", dut.core.cache.d_cache.data[i][j]);
            end
            $display("    LRU: %b", dut.core.cache.d_cache.lru[i]);
        end

        // MEM/WB Pipeline Registers
        $display("\n[🔄 MEM/WB REGISTERS]");
        $display("OUT: alu_out=%h mem_out=%h rd=%d memToReg=%b regWrite=%b",
            dut.core.registers_MEMWB.out_alu_out,
            dut.core.registers_MEMWB.out_mem_out,
            dut.core.registers_MEMWB.out_rd,
            dut.core.registers_MEMWB.out_mem_to_reg,
            dut.core.registers_MEMWB.out_write_enable
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

        case(opcode)
            7'b0110011: begin // R-type
                case({funct7, funct3})
                    10'b0000000000: asm = $sformatf("add x%0d,x%0d,x%0d", rd, rs1, rs2);
                    10'b0100000000: asm = $sformatf("sub x%0d,x%0d,x%0d", rd, rs1, rs2);
                    default: asm = "unknown-R";
                endcase
            end
            7'b0010011: asm = $sformatf("addi x%0d,x%0d,%0d", rd, rs1, $signed(imm_i));
            7'b1100011: begin // B-type
                case(funct3)
                    3'b001: asm = $sformatf("bne x%0d,x%0d,%0d", rs1, rs2, $signed(imm_b));
                    3'b000: asm = $sformatf("beq x%0d,x%0d,%0d", rs1, rs2, $signed(imm_b));
                    default: asm = "unknown-B";
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
endmodule