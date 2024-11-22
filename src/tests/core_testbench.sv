`timescale 1ps/1ps
`include "core.sv"

module core_testbench();

    logic clk;
    logic reset;

    parameter MAX_CYCLES = 26;  // Increased from 17
    integer cycle_count;

    // DUT instantiation
    core dut (
        .clk    (clk),
        .reset  (reset)
    );

    // Initialize test program
    initial begin
        // Test program for branch instructions
        dut.fetch.imemory.ROM[0]  = 32'h00100093; // addi x1, x0, 1
        dut.fetch.imemory.ROM[1]  = 32'h00200113; // addi x2, x0, 2
        dut.fetch.imemory.ROM[2]  = 32'h002081b3; // add x3, x1, x2
        dut.fetch.imemory.ROM[3]  = 32'h00302223; // sw x3, 4(x0)
        dut.fetch.imemory.ROM[4]  = 32'h00402203; // lw x4, 4(x0)
        dut.fetch.imemory.ROM[5]  = 32'h00209463; // bne x1, x2, 8
        dut.fetch.imemory.ROM[6]  = 32'h00500293; // addi x5, x0, 5 (skipped)
        dut.fetch.imemory.ROM[7]  = 32'h00600313; // addi x6, x0, 6 (skipped)
        dut.fetch.imemory.ROM[8]  = 32'h00700393; // addi x7, x0, 7
        dut.fetch.imemory.ROM[9]  = 32'h00738433; // add x8, x7, x7
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
            $display("FETCH STAGE\n IN:\nbranch_taken=%b new_PC=%h pc_write_disable=%b\n\nOUT:\nout_PC=%h out_instruction=%h %s\n", 
                //INPUT
                dut.fetch.branch_taken,
                dut.fetch.new_pc,
                dut.fetch.pc_write_disable,
                //OUTPUT
                dut.fetch.out_PC,
                dut.fetch.out_instruction,
                decode_instruction(dut.fetch.out_instruction));

            //Fetch to Decode registers
            $display("\n\nRegisters IFID\n IN: IFID_write_disable=%b\nOUT: out_PC=%h out_instruction=%h %s\n", 
                //INPUT
                dut.registers_IFID.in_IFID_write_disable,
                //OUTPUT
                dut.registers_IFID.out_PC,
                dut.registers_IFID.out_instruction,
                decode_instruction(dut.registers_IFID.out_instruction));

            $display("\n========================================\n");
            
            // Decode Stage
            $display("DECODE STAGE\n IN:\n   in_instruction=%h %s in_PC=%h\n\n   RF\n   write_enable=%b write_reg=%d write_data=%h\n\n   HAZARD\n   in_IFID_rs1=%d in_IFID_rs2=%d in_IDEX_rd=%d in_IDEX_mem_read=%b\n\nOUT:\n   out_PC=%h out_instruction=%h %s out_rs1=%d out_rs2=%d out_data_rs1=%h out_data_rs2=%h out_rd=%d out_immediate=%h\n\n   CONTROL\n   alu_src=%b alu_op=%b mem_write=%b mem_read=%b branch_inst=%b mem_to_reg=%b write_enable=%b\n\n   ALU\n   funct7=%b funct3=%b opcode=%b instr_type=%b\n\n   HAZARD\n   pc_write_disable=%b IFID_write_disable=%b\n",
                //INPUT
                dut.decode.in_instruction,
                decode_instruction(dut.decode.in_instruction),
                dut.decode.in_PC,
                //RF
                dut.decode.in_write_enable,
                dut.decode.in_write_reg,
                dut.decode.in_write_data,
                //HAZARD
                dut.decode.hazard_detection_unit.in_IFID_rs1,
                dut.decode.hazard_detection_unit.in_IFID_rs2,
                dut.decode.in_IDEX_rd,
                dut.decode.in_IDEX_mem_read,
                //OUTPUT
                dut.decode.out_PC,
                dut.decode.out_instruction,
                decode_instruction(dut.decode.out_instruction),
                dut.decode.out_rs1,
                dut.decode.out_rs2,
                dut.decode.out_data_a,
                dut.decode.out_data_b,
                dut.decode.out_rd,
                dut.decode.out_immediate,
                //CONTROL
                dut.decode.EX_alu_src,
                dut.decode.EX_alu_op,
                dut.decode.MEM_mem_write,
                dut.decode.MEM_mem_read,
                dut.decode.MEM_branch_inst,
                dut.decode.WB_write_mem_to_reg,
                dut.decode.WB_write_enable,
                //ALU
                dut.decode.out_funct7,
                dut.decode.out_funct3,
                dut.decode.out_opcode,
                dut.decode.out_instr_type,
                //HAZARD
                dut.decode.out_pc_write_disable,
                dut.decode.out_IFID_write_disable);
            
            // Decode to Execute registers
            $display("\n\nRegisters IDEX\nOUT:\n   out_PC=%h out_instruction=%h %s\n   out_immediate=%h\n   rs1=%d rs2=%d data_rs1=%h data_rs2=%h rd=%d\n\n   CONTROL\n   alu_src=%b alu_op=%b mem_write=%b mem_read=%b branch_inst=%b mem_to_reg=%b out_write_enable=%b \n\n   ALU\n   out_funct7=%b out_funct3=%b out_opcode=%b out_instr_type=%b\n",
                dut.registers_IDEX.out_PC,
                dut.registers_IDEX.out_instruction,
                decode_instruction(dut.registers_IDEX.out_instruction),
                dut.registers_IDEX.out_immediate,
                dut.registers_IDEX.out_rs1,
                dut.registers_IDEX.out_rs2,
                dut.registers_IDEX.out_data_rs1,
                dut.registers_IDEX.out_data_rs2,
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
            $display("EXECUTE STAGE\n IN:\n   in_PC=%h in_instruction=%h %s in_data_rs1=%h in_data_rs2=%h in_rd=%d in_immediate=%h\n\n   FORWARDING\n   in_rs1=%d in_rs2=%d in_EXMEM_rd=%d in_MEMWB_rd=%d in_EXMEM_write_enable=%b in_MEMWB_write_enable=%b EXMEM_alu_out=%h MEMWB_out_data=%h\n\n   CONTROL\n   in_alu_src=%b in_alu_op=%b in_mem_write=%b in_mem_read=%b in_branch_inst=%b in_mem_to_reg=%b in_write_enable=%b\n\n   ALU\n   funct7=%b funct3=%b opcode=%b instr_type=%b\n\nOUT:\n   out_alu_out=%h out_mem_in_data=%h out_rd=%d out_PC=%h \n\n   CONTROL\n   out_branch_taken=%b out_branch_inst=%b out_mem_write=%b out_mem_read=%b out_mem_to_reg=%b out_write_enable=%b out_branch_inst=%b\n",
                //INPUT
                dut.execute.in_PC,
                dut.execute.in_instruction,
                decode_instruction(dut.execute.in_instruction),
                dut.execute.in_data_rs1,
                dut.execute.in_data_rs2,
                dut.execute.in_IDEX_rd,
                dut.execute.in_immediate,
                //FORWARDING
                dut.execute.in_rs1,
                dut.execute.in_rs2,
                dut.execute.in_EXMEM_rd,
                dut.execute.in_MEMWB_rd,
                dut.execute.in_EXMEM_write_enable,
                dut.execute.in_MEMWB_write_enable,
                dut.execute.in_EXMEM_alu_out,
                dut.execute.in_MEMWB_out_data,
                //CONTROL
                dut.execute.in_alu_src,
                dut.execute.in_alu_op,
                dut.execute.in_mem_write,
                dut.execute.in_mem_read,
                dut.execute.in_branch_inst,
                dut.execute.in_mem_to_reg,
                dut.execute.in_write_enable,
                //ALU
                dut.execute.in_funct7,
                dut.execute.in_funct3,
                dut.execute.in_opcode,
                dut.execute.in_instr_type,
                //OUTPUT
                dut.execute.out_alu_out,
                dut.execute.out_mem_in_data,
                dut.execute.out_rd,
                dut.execute.out_PC,
                //CONTROL
                dut.execute.out_branch_taken,
                dut.execute.out_branch_inst,
                dut.execute.out_mem_write,
                dut.execute.out_mem_read,
                dut.execute.out_mem_to_reg,
                dut.execute.out_write_enable,
                dut.execute.out_branch_inst);

            // Execute to Memory registers
            $display("Registers EXMEM\nOUT:\n\n   TO FETCH\n   new_PC=%h branch_taken=%b branch_inst=%b\n\n   MEM\n   out_alu_out=%h out_mem_data=%h\n\n   CONTROL\n   mem_write=%b mem_read=%b rd=%d mem_to_reg=%b write_enable=%b\n",
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
            $display("MEMORY\n IN:\n   in_alu_out=%h in_mem_data=%h in_mem_write=%b in_mem_read=%b in_rd=%d in_mem_to_reg=%b in_write_enable=%b\n\nOUT:\n   out_alu_out=%h out_mem_out=%h out_rd=%d out_mem_to_reg=%b out_write_enable=%b\n",
                dut.dmemory.in_alu_out,
                dut.dmemory.in_mem_data,
                dut.dmemory.in_mem_write,
                dut.dmemory.in_mem_read,
                dut.dmemory.in_rd,
                dut.dmemory.in_mem_to_reg,
                dut.dmemory.in_write_enable,
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
            $display("WRITEBACK: out_rd=%d out_data=%h out_write_enable=%b\n",
                dut.writeback.out_rd,
                dut.writeback.out_data,
                dut.writeback.out_write_enable);

            // Register File Status
            $display("registers: r0=%h \nr1=%h \nr2=%h \nr3=%h",
                dut.decode.RF.registers[0],
                dut.decode.RF.registers[1],
                dut.decode.RF.registers[2],
                dut.decode.RF.registers[3]);
            $display("r4=%h\nr5=%h\nr6=%h\nr7=%h\nr8=%h\nr9=%h",
                dut.decode.RF.registers[4],
                dut.decode.RF.registers[5],
                dut.decode.RF.registers[6],
                dut.decode.RF.registers[7],
                dut.decode.RF.registers[8],
                dut.decode.RF.registers[9]);

            // Data Memory Status
            $display("dmemory: 0: %h 1: %h 2: %h 3: %h 4: %h 5: %h 6: %h 7: %h 8: %h 9: %h 10: %h 11: %h 12: %h 13: %h 14: %h 15: %h\n",
                dut.dmemory.dmemory.MEMORY[0],
                dut.dmemory.dmemory.MEMORY[1],
                dut.dmemory.dmemory.MEMORY[2],
                dut.dmemory.dmemory.MEMORY[3],
                dut.dmemory.dmemory.MEMORY[4],
                dut.dmemory.dmemory.MEMORY[5],
                dut.dmemory.dmemory.MEMORY[6],
                dut.dmemory.dmemory.MEMORY[7],
                dut.dmemory.dmemory.MEMORY[8],
                dut.dmemory.dmemory.MEMORY[9],
                dut.dmemory.dmemory.MEMORY[10],
                dut.dmemory.dmemory.MEMORY[11],
                dut.dmemory.dmemory.MEMORY[12],
                dut.dmemory.dmemory.MEMORY[13],
                dut.dmemory.dmemory.MEMORY[14],
                dut.dmemory.dmemory.MEMORY[15]);
            

            $display("\n\n\n");
            $fflush();  // Force output to display immediately
        end
    end

    // Add specific branch-related monitoring
    always @(posedge clk) begin
        if (!reset) begin
            // Monitor branch-related signals
            $display("\nBranch Control Signals:");
            $display("Branch Taken (EXMEM): %b", dut.registers_EXMEM.out_branch_taken);
            $display("Previous cycle EX stage branch taken: %b", dut.execute.out_branch_taken);
            $display("Previous cycle ALU branch taken: %b", dut.execute.alu.branch_taken);
            
            // Monitor PC changes
            $display("Current PC: %h", dut.fetch.out_PC);
            $display("New PC (if branch): %h", dut.execute.out_PC);

            // Monitor register values for branch testing
            $display("\nRelevant Register Values:");
            $display("x1 (rs1): %h", dut.decode.RF.registers[1]);
            $display("x2 (rs2): %h", dut.decode.RF.registers[2]);
            $display("x3: %h", dut.decode.RF.registers[3]);
            $display("x4: %h", dut.decode.RF.registers[4]);
            $display("x5: %h", dut.decode.RF.registers[5]);
            $display("x6: %h", dut.decode.RF.registers[6]);
            $display("x7: %h", dut.decode.RF.registers[7]);
            $display("x8: %h", dut.decode.RF.registers[8]);
        end
    end

    // Dump waves
    initial begin
        $dumpfile("core_testbench.vcd");
        $dumpvars(0, core_testbench);
    end

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
                    10'b0000000000: asm = $sformatf("add x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'b0100000000: asm = $sformatf("sub x%0d, x%0d, x%0d", rd, rs1, rs2);
                    // Add more R-type instructions as needed
                    default: asm = "unknown-R";
                endcase
            end
            
            7'b0010011: begin // I-type
                case(funct3)
                    3'b000: asm = $sformatf("addi x%0d, x%0d, %0d", rd, rs1, $signed(imm_i));
                    // Add more I-type instructions as needed
                    default: asm = "unknown-I";
                endcase
            end
            
            7'b0100011: begin // S-type
                case(funct3)
                    3'b010: asm = $sformatf("sw x%0d, %0d(x%0d)", rs2, $signed(imm_s), rs1);
                    // Add more S-type instructions as needed
                    default: asm = "unknown-S";
                endcase
            end
            
            7'b1100011: begin // B-type
                case(funct3)
                    3'b001: asm = $sformatf("bne x%0d, x%0d, %0d", rs1, rs2, $signed(imm_b));
                    3'b000: asm = $sformatf("beq x%0d, x%0d, %0d", rs1, rs2, $signed(imm_b));
                    // Add more B-type instructions as needed
                    default: asm = "unknown-B";
                endcase
            end
            
            7'b0000011: begin // Load I-type
                case(funct3)
                    3'b010: asm = $sformatf("lw x%0d, %0d(x%0d)", rd, $signed(imm_i), rs1);
                    // Add more load instructions as needed
                    default: asm = "unknown-load";
                endcase
            end
            
            default: begin
                if (instruction == 32'h00000013)
                    asm = "nop";
                else
                    asm = "unknown";
            end
        endcase
        
        return asm;
    endfunction
endmodule
