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

        for(int i = 32'h80; i < 32'h87; i = i+1) begin
            $display("%h", dut.memory.memory[i]);
        end

        reset = 1;
        #2 reset = 0;

        repeat(290) begin
            #2;
            display_processor_state();
        end
        $finish;
    end
    task automatic display_processor_state;
        $display("\n╔═══════════════════ CYCLE %0d ════════════════════╗", $time/2);
        
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

        // IF/ID Pipeline Registers
        $display("\n[🔄 IF/ID REGISTERS]");
        $display("IN: IFID_write_disable=%b", dut.core.registers_IFID.in_IFID_write_disable);
        $display("OUT: PC=%h instruction=%h (%s)",
            dut.core.registers_IFID.out_PC,
            dut.core.registers_IFID.out_instruction,
            decode_instruction(dut.core.registers_IFID.out_instruction)
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
        $display("OUT: PC=%h instruction=%h (%s)",
            dut.core.registers_IDEX.out_PC,
            dut.core.registers_IDEX.out_instruction,
            decode_instruction(dut.core.registers_IDEX.out_instruction)
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
        $display("  Forwarding: rs1=%d rs2=%d EXMEM_rd=%d EXMEM_write_enable=%b MEMWB_rd=%d MEMWB_write_enable=%b",
            dut.core.execute.in_rs1,
            dut.core.execute.in_rs2,
            dut.core.execute.in_EXMEM_rd,
            dut.core.execute.in_EXMEM_write_enable,
            dut.core.execute.in_MEMWB_rd,
            dut.core.execute.in_MEMWB_write_enable
        );
        $display(" Operand1: %h Operand2: %h",
            dut.core.execute.alu_operand1,
            dut.core.execute.alu_operand2
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

endmodule
