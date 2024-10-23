module core (
    input clk,
    output [31:0] OUT_PC,
    output [31:0] OUT_IR,
    output [31:0] OUT_AluIn1,
    output [31:0] OUT_AluIn2,
    output [31:0] OUT_AluOut
);

    parameter LW = 7'b000_0011;
    parameter SW = 7'b010_0011;
    parameter BEQ = 7'b110_001;
    parameter NOP = 32'h0000_0013;
    parameter ALUOp = 7'b001_0011;

    reg [31:0] PC;
    reg [31:0] RF [0:31];

    //Pipeline registers
    reg [31:0] IDEX_A, IDEX_B, EXMEM_B, EXMEM_ALUOut, MEMWB_Value;

    //Separate memories
    reg [31:0] IMemory [0:1023], DMemory [0:1023];

    //Registers to pipeline instruction
    reg [31:0] IFID_IR, IDEX_IR, EXMEM_IR, MEMWB_IR;

    wire [4:0] IFID_rs1, IFID_rs2, MEMWB_rd;
    wire [6:0] IDEX_Op, EXMEM_Op, MEMWB_Op;
    wire [31:0] AluIn1, AluIn2;

    assign IFID_rs1 = IFID_IR[19:15]; // rs1 field
    assign IFID_rs2 = IFID_IR[24:20]; // rs2 field
    assign IDEX_Op = IDEX_IR[6:0];    // opcode
    assign IDEX_rs1 = IDEX_IR[19:15];
    assign IDEX_rs2 = IDEX_IR[24:20];
    assign EXMEM_Op = EXMEM_IR[6:0];  // the opcode
    assign EXMEM_rd = EXMEM_IR[11:7];
    assign MEMWB_Op = MEMWB_IR[6:0];  // the opcode
    assign MEMWB_rd = MEMWB_IR[11:7]; // rd field

    assign AluIn1 = IDEX_A;
    assign AluIn2 = IDEX_B;

    wire bypassAluIn1fromMEM; 
    wire bypassAluIn1fromALUinWB;

    wire bypassAluIn2fromMEM; 
    wire bypassAluIn2fromALUinWB;

    wire bypassAluIn1fromLDinWB;
    wire bypassAluIn2fromLDinWB;

    assign bypassAluIn1fromMEM = (IDEX_rs1 == EXMEM_rd) && (IDEX_rs1 != 0) && (EXMEM_Op == ALUOp);
    assign bypassAluIn2fromMEM = (IDEX_rs2 == EXMEM_rd) && (IDEX_rs2 != 0) && (EXMEM_Op == ALUOp);

    assign bypassAluIn1fromALUinWB = (IDEX_rs1 == MEMWB_rd) && (IDEX_rs1 != 0) && (MEMWB_Op == ALUOp);
    assign bypassAluIn2fromALUinWB = (IDEX_rs2 == MEMWB_rd) && (IDEX_rs2 != 0) && (MEMWB_Op == ALUOp);

    assign bypassAluIn1fromLDinWB = (IDEX_rs1 == MEMWB_rd) && (IDEX_rs1 != 0) && (MEMWB_Op == LW);
    assign bypassAluIn2fromLDinWB = (IDEX_rs2 == MEMWB_rd) && (IDEX_rs2 != 0) && (MEMWB_Op == LW);

    
    assign AluIn1 = bypassAluIn1fromMEM ? EXMEM_ALUOut :
    (bypassAluIn1fromALUinWB || bypassAluIn1fromLDinWB) ? MEMWB_Value : IDEX_A;

    assign AluIn2 = bypassAluIn2fromMEM ? EXMEM_ALUOut :
    (bypassAluIn2fromALUinWB || bypassAluIn2fromLDinWB) ? MEMWB_Value : IDEX_B;

    //Init the regs
    integer i;
    initial begin
        IFID_IR = NOP; IDEX_IR = NOP; EXMEM_IR = NOP; MEMWB_IR = NOP;
        PC = 0;
        for (i=0;i<32;i=i+1) RF[i] = 0;
        for (i=0;i<32;i=i+1) IMemory[i] = 32'b0000000_00001_00001_000_00001_001_0011;
    end

    always @(posedge clk) begin
        //IF stage
        IFID_IR <= IMemory[PC >> 2];
        PC <= PC+4;

        //ID stage
        IDEX_A <= RF[IFID_rs1]; 
        IDEX_B <= RF[IFID_rs2]; 
        IDEX_IR <= IFID_IR; 

        //EX stage
        if (IDEX_Op == LW)
            EXMEM_ALUOut <= IDEX_A + {{53{IDEX_IR[31]}}, IDEX_IR[30:20]}; // rs1 + Immediate for load
        else if (IDEX_Op == SW)
            EXMEM_ALUOut <= IDEX_A + {{53{IDEX_IR[31]}}, IDEX_IR [30:25], IDEX_IR[11:7]}; // rs1 + Immediate for store
        else if (IDEX_Op == ALUOp) //If R-Type
            case (IDEX_IR[31:25]) // case for the various R-type instructions. This is case funct7 for R-Type instructions
                0: EXMEM_ALUOut <= AluIn1 + AluIn2; // add operation

                default: EXMEM_ALUOut <= 0;
            endcase

        EXMEM_IR <= IDEX_IR; 

        //MEM stage
        EXMEM_B <= IDEX_B; // pass along the IR & B register
                           // Mem stage of pipeline
        if (EXMEM_Op == ALUOp) 
            MEMWB_Value <= EXMEM_ALUOut; // pass along ALU result
        else if (EXMEM_Op == LW) MEMWB_Value <= DMemory[EXMEM_ALUOut >> 2];
        else if (EXMEM_Op == SW) DMemory[EXMEM_ALUOut >> 2] <= EXMEM_B; //store
        MEMWB_IR <= EXMEM_IR; // pass along IR

        // WB stage
        if (((MEMWB_Op == LW) || (MEMWB_Op == ALUOp)) && (MEMWB_rd != 0))
            RF[MEMWB_rd] <= MEMWB_Value;
    end


    assign OUT_PC = PC;
    assign OUT_IR = IFID_IR;
    assign OUT_AluIn1 = AluIn1;
    assign OUT_AluIn2 = AluIn2;
    assign OUT_AluOut = EXMEM_ALUOut;

endmodule
