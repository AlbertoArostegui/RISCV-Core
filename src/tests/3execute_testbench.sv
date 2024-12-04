`include "stage3_execute.sv"

module execute_testbench ();

    logic clk;
    logic reset;

    logic [31:0] instruction;
    logic [31:0] PC;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] immediate;

    logic alu_src;
    logic [2:0] alu_op;

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] EXMEM_rd;
    logic [4:0] MEMWB_rd;
    logic EXMEM_write_enable;
    logic MEMWB_write_enable;
    logic [31:0] EXMEM_alu_out;
    logic [31:0] MEMWB_out_data;

    logic [6:0] funct7;
    logic [2:0] funct3;
    logic [6:0] opcode;
    logic [2:0] instr_type;

    logic mem_write;
    logic mem_read;
    logic branch_inst;

    logic mem_to_reg;
    logic write_enable;

    logic [31:0] alu_out;
    logic [31:0] out_PC;
    logic branch_taken;
    logic flush;

    logic [4:0] rd;
    logic [31:0] mem_in_data;
    logic out_mem_write;
    logic out_mem_read;
    logic out_branch_inst;
    logic out_mem_to_reg;
    logic out_write_enable;

    stage_execute dut(
        .clk(clk),
        .reset(reset),
        .in_instruction(instruction),
        .in_PC(PC),
        .in_data_rs1(rs1_data),
        .in_data_rs2(rs2_data),
        .in_immediate(immediate),
        .in_alu_src(alu_src),
        .in_alu_op(alu_op),
        .in_rs1(rs1),
        .in_rs2(rs2),
        .in_EXMEM_rd(EXMEM_rd),
        .in_MEMWB_rd(MEMWB_rd),
        .in_EXMEM_write_enable(EXMEM_write_enable),
        .in_MEMWB_write_enable(MEMWB_write_enable),
        .in_EXMEM_alu_out(EXMEM_alu_out),
        .in_MEMWB_out_data(MEMWB_out_data),
        .in_funct7(funct7),
        .in_funct3(funct3),
        .in_opcode(opcode),
        .in_instr_type(instr_type),
        .in_mem_write(mem_write),
        .in_mem_read(mem_read),
        .in_branch_inst(branch_inst),
        .in_mem_to_reg(mem_to_reg),
        .in_write_enable(write_enable),
        .out_alu_out(alu_out),
        .out_PC(out_PC),
        .out_branch_taken(branch_taken),
        .out_flush(flush),
        .out_rd(rd),
        .out_mem_in_data(mem_in_data),
        .out_mem_write(out_mem_write),
        .out_mem_read(out_mem_read),
        .out_branch_inst(out_branch_inst),
        .out_mem_to_reg(out_mem_to_reg),
        .out_write_enable(out_write_enable)
    );

    initial begin
        // Initialize clock
        clk = 0;
        forever #1 clk = ~clk;
    end

    initial begin
        // Initialize inputs
        reset = 1;
        instruction = 0;
        PC = 0;
        rs1_data = 0;
        rs2_data = 0;
        immediate = 0;
        alu_src = 0;
        alu_op = 0;
        rs1 = 0;
        rs2 = 0;
        EXMEM_rd = 0;
        MEMWB_rd = 0;
        EXMEM_write_enable = 0;
        MEMWB_write_enable = 0;
        EXMEM_alu_out = 0;
        MEMWB_out_data = 0;
        funct7 = 0;
        funct3 = 0;
        opcode = 0;
        instr_type = 0;
        mem_write = 0;
        mem_read = 0;
        branch_inst = 0;
        mem_to_reg = 0;
        write_enable = 0;

        // Release reset
        #2 reset = 0;

        // Test case 1: ADD
        rs1_data = 32'h00000005;
        rs2_data = 32'h00000003;
        alu_op = 3'b000; // ADD operation
        opcode = 7'b0110011; // R-type
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #10;
        $display("ADD: alu_out = %h", alu_out);

        // Test case 2: ADDI
        rs1_data = 32'h00000005;
        immediate = 32'h00000003;
        alu_op = 3'b000; // ADDI operation
        alu_src = 1;
        opcode = 7'b0010011; // I-type
        funct3 = 3'b000;
        #10;
        $display("ADDI: alu_out = %h", alu_out);

        // Test case 3: BEQ 
        rs1_data = 32'h00000005;
        rs2_data = 32'h00000005;
        alu_op = 3'b001; // BEQ operation
        opcode = 7'b1100011; // B-type
        funct3 = 3'b000;
        branch_inst = 1;
        #10;
        $display("BEQ: branch_taken = %b | Should be 1", branch_taken);

        // Test case 3: BEQ 
        rs1_data = 32'h00000005;
        rs2_data = 32'h00000003;
        opcode = 7'b1100011; // B-type
        funct3 = 3'b000;
        branch_inst = 1;
        #10;
        $display("BEQ: branch_taken = %b | Should be 0", branch_taken);

        // Test case 4: BNE (branch not taken)
        rs1_data = 32'h00000005;
        rs2_data = 32'h00000003;
        opcode = 7'b1100011; // B-type
        funct3 = 3'b001;
        branch_inst = 1;
        #10;
        $display("BNE: branch_taken = %b | Should be 1", branch_taken);

        // Test case 4: BNE (branch not taken)
        rs1_data = 32'h00000005;
        rs2_data = 32'h00000005;
        opcode = 7'b1100011; // B-type
        funct3 = 3'b001;
        branch_inst = 1;
        #10;
        $display("BNE: branch_taken = %b | Should be 0", branch_taken);

        $finish;
    end

endmodule