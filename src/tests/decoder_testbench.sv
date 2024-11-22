`include "decoder.sv"
`timescale 1 ns / 100 ps

module decoder_testbench();

    parameter INSTR_SIZE = 32;

    // Inputs
    reg [INSTR_SIZE-1:0] instr;

    // Outputs
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [31:0] imm;
    wire [6:0] funct7;
    wire [2:0] funct3;
    wire [6:0] opcode;
    wire [2:0] instr_type;

    // Instantiate the decoder
    decoder dut (
        .instr(instr),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm(imm),
        .funct7(funct7),
        .funct3(funct3),
        .opcode(opcode),
        .instr_type(instr_type)
    );

    // For waveform dumping
    initial begin
        $dumpfile("decoder_testbench.vcd");
        $dumpvars(0, decoder_testbench);
    end

    // Test stimulus
    initial begin
        // Test case 1: ADD
        $display("\nTest Case 1: ADD x1, x2, x3");
        instr = 32'h003100b3;  // add x1, x2, x3
        #1;
        if (rs1 !== 5'd2) $error("ADD: rs1 incorrect. Expected 2, got %d", rs1);
        if (rs2 !== 5'd3) $error("ADD: rs2 incorrect. Expected 3, got %d", rs2);
        if (rd !== 5'd1)  $error("ADD: rd incorrect. Expected 1, got %d", rd);
        if (funct7 !== 7'b0000000) $error("ADD: funct7 incorrect");
        if (funct3 !== 3'b000) $error("ADD: funct3 incorrect");
        if (opcode !== 7'b0110011) $error("ADD: opcode incorrect");

        // Test case 2: ADDI
        $display("\nTest Case 2: ADDI x1, x1, 5");
        instr = 32'h00508093;  // addi x1, x1, 5
        #1;
        if (rs1 !== 5'd1) $error("ADDI: rs1 incorrect. Expected 1, got %d", rs1);
        if (rd !== 5'd1)  $error("ADDI: rd incorrect. Expected 1, got %d", rd);
        if (imm !== 32'd5) $error("ADDI: immediate incorrect. Expected 5, got %d", imm);
        if (funct3 !== 3'b000) $error("ADDI: funct3 incorrect");
        if (opcode !== 7'b0010011) $error("ADDI: opcode incorrect");

        // Test case 3: SUB
        $display("\nTest Case 3: SUB x2, x3, x4");
        instr = 32'h40418133;  // sub x2, x3, x4
        #1;
        if (rs1 !== 5'd3) $error("SUB: rs1 incorrect. Expected 3, got %d", rs1);
        if (rs2 !== 5'd4) $error("SUB: rs2 incorrect. Expected 4, got %d", rs2);
        if (rd !== 5'd2)  $error("SUB: rd incorrect. Expected 2, got %d", rd);
        if (funct7 !== 7'b0100000) $error("SUB: funct7 incorrect");
        if (funct3 !== 3'b000) $error("SUB: funct3 incorrect");
        if (opcode !== 7'b0110011) $error("SUB: opcode incorrect");

        // Test case 4: LOAD
        $display("\nTest Case 4: LW x1, 4(x2)");
        instr = 32'h00412083;  // lw x1, 4(x2)
        #1;
        if (rs1 !== 5'd2) $error("LOAD: rs1 incorrect. Expected 2, got %d", rs1);
        if (rd !== 5'd1)  $error("LOAD: rd incorrect. Expected 1, got %d", rd);
        if (imm !== 32'd4) $error("LOAD: immediate incorrect. Expected 4, got %d", imm);
        if (funct3 !== 3'b010) $error("LOAD: funct3 incorrect");
        if (opcode !== 7'b0000011) $error("LOAD: opcode incorrect");

        // Test case 5: STORE
        $display("\nTest Case 5: SW x1, 8(x2)");
        instr = 32'h00112423;  // sw x1, 8(x2)
        #1;
        if (rs1 !== 5'd2) $error("STORE: rs1 incorrect. Expected 2, got %d", rs1);
        if (rs2 !== 5'd1) $error("STORE: rs2 incorrect. Expected 1, got %d", rs2);
        if (imm !== 32'd8) $error("STORE: immediate incorrect. Expected 8, got %d", imm);
        if (funct3 !== 3'b010) $error("STORE: funct3 incorrect");
        if (opcode !== 7'b0100011) $error("STORE: opcode incorrect");

        // Test case 6: BRANCH
        $display("\nTest Case 6: BEQ x1, x2, 12");
        instr = 32'h00208663;  // beq x1, x2, 12
        #1;
        if (rs1 !== 5'd1) $error("BRANCH: rs1 incorrect. Expected 1, got %d", rs1);
        if (rs2 !== 5'd2) $error("BRANCH: rs2 incorrect. Expected 2, got %d", rs2);
        if (imm !== 32'd12) $error("BRANCH: immediate incorrect. Expected 12, got %d", imm);
        if (funct3 !== 3'b000) $error("BRANCH: funct3 incorrect");
        if (opcode !== 7'b1100011) $error("BRANCH: opcode incorrect, got %b", opcode);

        // Test case 7: JAL
        $display("\nTest Case 7: JAL x1, 16");
        instr = 32'h010000ef;  // jal x1, 16
        #1;
        if (rd !== 5'd1) $error("JAL: rd incorrect. Expected 1, got %d", rd);
        if (imm !== 32'd16) $error("JAL: immediate incorrect. Expected 16, got %d", imm);
        if (opcode !== 7'b1101111) $error("JAL: opcode incorrect");

        // Test case 8: MUL
        $display("\nTest Case 8: MUL x2, x3, x4");
        instr = 32'h02418133;  // mul x2, x3, x4
        #1;
        if (rs1 !== 5'd3) $error("MUL: rs1 incorrect. Expected 3, got %d", rs1);
        if (rs2 !== 5'd4) $error("MUL: rs2 incorrect. Expected 4, got %d", rs2);
        if (rd !== 5'd2)  $error("MUL: rd incorrect. Expected 2, got %d", rd);
        if (funct7 !== 7'b0000001) $error("MUL: funct7 incorrect");
        if (opcode !== 7'b0110011) $error("MUL: opcode incorrect");

        // Test case 9: BNE
        $display("\nTest Case 9: BNE x1, x2, 8");
        instr = 32'h00209463;  // bne x1, x2, 8
        #1;
        if (rs1 !== 5'd1) $error("BNE: rs1 incorrect. Expected 1, got %d", rs1);
        if (rs2 !== 5'd2) $error("BNE: rs2 incorrect. Expected 2, got %d", rs2);
        if (imm !== 32'd8) $error("BNE: immediate incorrect. Expected 8, got %d", imm);
        if (funct3 !== 3'b001) $error("BNE: funct3 incorrect");
        if (opcode !== 7'b1100011) $error("BNE: opcode incorrect");

        $display("\nAll tests completed!");
        $finish;
    end

endmodule
