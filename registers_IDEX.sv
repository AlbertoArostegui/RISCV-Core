module registers_IDEX(
    input clk,
    input reset,
    
    //IN
    //For passing
    input [31:0] in_instruction,
    input [31:0] in_PC,
    input [31:0] in_immediate,

    input [31:0] in_rs1,
    input [31:0] in_rs2,
    input [4:0] in_rd,

    //For alu
    input in_alu_src,
    input [2:0] in_alu_op,
    input [6:0] in_funct7,
    input [2:0] in_funct3,
    input [5:0] in_opcode,
    input [2:0] in_instr_type,
    
    //OUT
    output reg [31:0] out_instruction,
    output reg [31:0] out_PC,
    output reg [31:0] out_immediate,

    output reg [31:0] out_rs1,
    output reg [31:0] out_rs2,
    output reg [4:0] out_rd,

    //For alu
    output reg out_alu_src,
    output reg [2:0] out_alu_op,

    output reg [6:0] out_funct7,
    output reg [2:0] out_funct3,
    output reg [5:0] out_opcode,
    output reg [2:0] out_instr_type
);

    always @(posedge clk) begin
        out_instruction <= in_instruction;
        out_immediate <= in_immediate;
        out_PC <= in_PC;

        out_rs1 <= in_rs1;
        out_rs2 <= in_rs2;
        out_rd <= in_rd;

        out_alu_src <= in_alu_src;
        out_alu_op <= in_alu_op;
        out_funct7 <= in_funct7;
        out_funct3 <= in_funct3;
        out_opcode <= in_opcode;

        out_instr_type <= in_instr_type;
    end
endmodule
