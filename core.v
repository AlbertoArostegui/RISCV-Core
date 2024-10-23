`include "memory.v"
`include "alu.v"

module core (
    input CLK,
    input RESET,
    output [31:0] out,
    output [3:0] pc_out,
    output [31:0] alu_out,
    output [31:0] inst_out
);

    wire [31:0] instr;
    wire [31:0] mem_data;
    wire zero;
    memory mem(.CLK(CLK), .mem_addr(PC), .inst_out(instr));
    alu alu(.CLK(CLK), .funct3(funct3), .funct7(funct7), .operand1(rs1), .operand2(aluIn2), .aluOut(alu_out), .zero(zero));

    reg [3:0] PC = 0;           //Program counter
    reg [31:0] RF [0:31];       //Register file with 32 general purpouse registers
    
    initial begin

        RF[0] = 32'b00000000_00000000_00000000_00000000;
        RF[1] = 32'b00000000_00000000_00000000_00000000;
        RF[2] = 32'b00000000_00000000_00000000_00001111;
        RF[3] = 32'b00000000_00000000_00000000_00001001;
        RF[4] = 32'b00000000_00000000_00000000_00000000;
        RF[5] = 32'b00000000_00000000_00000000_00000000;
        RF[6] = 32'b00000000_00000000_00000000_00000000;
        RF[7] = 32'b00000000_00000000_00000000_00000000;
        RF[8] = 32'b00000000_00000000_00000000_00000000;
        RF[9] = 32'b00000000_00000000_00000000_00000000;

    end

    wire isALUreg  =  (instr[6:0] == 7'b0110011); // rd <- rs1 OP rs2   
    wire isALUimm  =  (instr[6:0] == 7'b0010011); // rd <- rs1 OP Iimm
    wire isBranch  =  (instr[6:0] == 7'b1100011); // if(rs1 OP rs2) PC<-PC+Bimm
    wire isJALR    =  (instr[6:0] == 7'b1100111); // rd <- PC+4; PC<-rs1+Iimm
    wire isJAL     =  (instr[6:0] == 7'b1101111); // rd <- PC+4; PC<-PC+Jimm
    wire isAUIPC   =  (instr[6:0] == 7'b0010111); // rd <- PC + Uimm
    wire isLUI     =  (instr[6:0] == 7'b0110111); // rd <- Uimm   
    wire isLoad    =  (instr[6:0] == 7'b0000011); // rd <- mem[rs1+Iimm]
    wire isStore   =  (instr[6:0] == 7'b0100011); // mem[rs1+Simm] <- rs2
    wire isSYSTEM  =  (instr[6:0] == 7'b1110011); // special

    //Different instruction types
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    //Registers targeted by the instruction
    wire [4:0] rs1Id = instr[19:15];
    wire [4:0] rs2Id = instr[24:20];
    wire [4:0] atRd = instr[11:7];

    //Immediate value
    wire [31:0] Uimm={    instr[31],   instr[30:12], {12{1'b0}}};
    wire [31:0] Iimm={{21{instr[31]}}, instr[30:20]};
    wire [31:0] Simm={{21{instr[31]}}, instr[30:25],instr[11:7]};
    wire [31:0] Bimm={{20{instr[31]}}, instr[7],instr[30:25],instr[11:8],1'b0};
    wire [31:0] Jimm={{12{instr[31]}}, instr[19:12],instr[20],instr[30:21],1'b0};

    wire [31:0] wbData;
    wire wbEnable;

    wire [31:0] rs1;
    wire [31:0] rs2;
    wire [31:0] rd;

    wire [31:0] aluIn2 = (isALUreg) ? rs2 : Iimm;

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            PC <= 0;
        end else begin
            PC <= (PC == 15) ? 0 : PC + 1;

            //rs1 <= RF[rs1Id]; 
            //rs2 <= RF[rs2Id]; 

            //wbEnable <= isALUreg || isALUimm || isJALR || isJAL || isLUI;

            //if (isALUreg || isALUimm) begin
                //wbData <= alu_out;
            //end
            
            //if (wbEnable)
                //RF[atRd] <= wbData;
                //out <= wbData;
            RF[atRd] <= (wbEnable) ? wbData : 0;
        end
    end

    assign rs1 = RF[rs1Id];
    assign rs2 = RF[rs2Id];
    assign wbEnable = isALUreg || isALUimm || isJALR || isJAL || isLUI;
    assign wbData = alu_out;
    assign out = (wbEnable) ? wbData : 0;
    assign pc_out = PC;
    assign inst_out = instr;

endmodule
