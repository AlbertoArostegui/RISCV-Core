`include "control.sv"
`timescale 1 ns / 100 ps

module control_testbench();
    // Inputs
    reg [31:0] in_instruction;

    // Outputs
    wire EX_alu_src;
    wire [2:0] EX_alu_op;
    wire MEM_mem_write;
    wire MEM_mem_read;
    wire MEM_branch_inst;
    wire WB_write_mem_to_reg;
    wire WB_write_enable;

    // Instantiate the control unit
    control dut (
        .in_instruction(in_instruction),
        .EX_alu_src(EX_alu_src),
        .EX_alu_op(EX_alu_op),
        .MEM_mem_write(MEM_mem_write),
        .MEM_mem_read(MEM_mem_read),
        .MEM_branch_inst(MEM_branch_inst),
        .WB_write_mem_to_reg(WB_write_mem_to_reg),
        .WB_write_enable(WB_write_enable)
    );

    // For waveform dumping
    initial begin
        $dumpfile("control_testbench.vcd");
        $dumpvars(0, control_testbench);
    end

    // Test stimulus
    initial begin
        // Test case 1: R-type (ADD)
        $display("\nTest Case 1: R-type (ADD)");
        in_instruction = 32'h003100b3;  // add x1, x2, x3
        #1;
        if (EX_alu_src !== 0) $error("ADD: EX_alu_src should be 0");
        if (MEM_mem_write !== 0) $error("ADD: MEM_mem_write should be 0");
        if (MEM_mem_read !== 0) $error("ADD: MEM_mem_read should be 0");
        if (MEM_branch_inst !== 0) $error("ADD: MEM_branch_inst should be 0");
        if (WB_write_enable !== 1) $error("ADD: WB_write_enable should be 1");
        if (WB_write_mem_to_reg !== 0) $error("ADD: WB_write_mem_to_reg should be 0");

        // Test case 2: I-type (LOAD)
        $display("\nTest Case 2: I-type (LOAD)");
        in_instruction = 32'h00412083;  // lw x1, 4(x2)
        #1;
        if (EX_alu_src !== 1) $error("LOAD: EX_alu_src should be 1");
        if (MEM_mem_write !== 0) $error("LOAD: MEM_mem_write should be 0");
        if (MEM_mem_read !== 1) $error("LOAD: MEM_mem_read should be 1");
        if (MEM_branch_inst !== 0) $error("LOAD: MEM_branch_inst should be 0");
        if (WB_write_enable !== 1) $error("LOAD: WB_write_enable should be 1");
        if (WB_write_mem_to_reg !== 1) $error("LOAD: WB_write_mem_to_reg should be 1");

        // Test case 3: S-type (STORE)
        $display("\nTest Case 3: S-type (STORE)");
        in_instruction = 32'h00112423;  // sw x1, 8(x2)
        #1;
        if (EX_alu_src !== 1) $error("STORE: EX_alu_src should be 1");
        if (MEM_mem_write !== 1) $error("STORE: MEM_mem_write should be 1");
        if (MEM_mem_read !== 0) $error("STORE: MEM_mem_read should be 0");
        if (MEM_branch_inst !== 0) $error("STORE: MEM_branch_inst should be 0");
        if (WB_write_enable !== 0) $error("STORE: WB_write_enable should be 0");
        if (WB_write_mem_to_reg !== 0) $error("STORE: WB_write_mem_to_reg should be 0");

        // Test case 4: B-type (BRANCH)
        $display("\nTest Case 4: B-type (BRANCH)");
        in_instruction = 32'h00208663;  // beq x1, x2, 12
        #1;
        if (EX_alu_src !== 0) $error("BRANCH: EX_alu_src should be 0");
        if (MEM_mem_write !== 0) $error("BRANCH: MEM_mem_write should be 0");
        if (MEM_mem_read !== 0) $error("BRANCH: MEM_mem_read should be 0");
        if (MEM_branch_inst !== 1) $error("BRANCH: MEM_branch_inst should be 1");
        if (WB_write_enable !== 0) $error("BRANCH: WB_write_enable should be 0");
        if (WB_write_mem_to_reg !== 0) $error("BRANCH: WB_write_mem_to_reg should be 0");

        // Test case 5: I-type (ADDI)
        $display("\nTest Case 5: I-type (ADDI)");
        in_instruction = 32'h00508093;  // addi x1, x1, 5
        #1;
        if (EX_alu_src !== 0) $error("ADDI: EX_alu_src should be 0");
        if (MEM_mem_write !== 0) $error("ADDI: MEM_mem_write should be 0");
        if (MEM_mem_read !== 0) $error("ADDI: MEM_mem_read should be 0");
        if (MEM_branch_inst !== 0) $error("ADDI: MEM_branch_inst should be 0");
        if (WB_write_enable !== 1) $error("ADDI: WB_write_enable should be 1");
        if (WB_write_mem_to_reg !== 0) $error("ADDI: WB_write_mem_to_reg should be 0");

        $display("\nAll tests completed!");
        $finish;
    end

endmodule