`timescale 1 ns / 1 ns

module alu (
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    input [31:0] operand1,
    input [31:0] operand2,
    input [31:0] immediate,
    input [31:0] PC,
    output reg [31:0] alu_out,
    output reg [31:0] out_PC,
    output reg branch_taken
);

    always @(*) begin
        out_PC = PC + immediate;
        case (opcode)
            7'b0110011: //ALU OPS
                case (funct7)
                    7'b0100000: //SUB rd, rs1, rs2
                        alu_out = operand1 - operand2;
                    7'b0000001: //MUL rd, rs1, rs2
                        alu_out = operand1 * operand2;
                    7'b0000000: 
                        case (funct3)
                            3'b000: //ADD rd, rs1, rs2
                                alu_out = operand1 + operand2;
                            3'b111: //AND rd, rs1, rs2, BITWISE AND OPERATOR
                                alu_out = operand1 & operand2; 
                            3'b110: //OR rd, rs1, rs2, BITWISE OR OPERATOR
                                alu_out = operand1 | operand2;
                            default:
                                alu_out = 0;
                        endcase
                    default:
                        alu_out = 0;
                endcase
            7'b0010011: //ALU OPS IMMEDIATES
                case (funct3)
                    3'b000: //ADDI rd, rs1, imm12
                        alu_out = operand1 + immediate;
                    3'b001: //SLLI rd, rs1, imm12. Shift left logical immediate
                        alu_out = operand1 << operand2;
                    3'b101: //SRLI rd, rs1, imm12. Shift right logical immediate
                        alu_out = operand1 >> operand2;
                    default:
                        alu_out = 0;
                endcase
            7'b0010111: //AUIP rd, imm20 -- rd <- PC + imm20 << 12 -- Add upper immediate to PC
                alu_out = out_PC;
            7'b0110111: //LUI rd, imm20 -- rd <- imm20 << 12 -- Load upper immediate
                alu_out = immediate;                
            7'b1100011: //Branching
                case (funct3)
                    3'b000: begin //BEQ rs1, rs2, imm7
                        branch_taken = operand1 == operand2;
                        alu_out = operand1 - operand2; //operand1 - operand2 = 0? -> then take branch
                    end
                    3'b010: begin //BNE rs1, rs2, imm7
                        branch_taken = operand1 != operand2;
                        alu_out = operand1 - operand2;
                    end
                    3'b100: begin //BLT rs1, rs2, imm12
                        branch_taken = operand1 < operand2;
                        alu_out = operand1 - operand2;
                    end
                    3'b101: begin //BGE rs1, rs2, imm7
                        branch_taken = (operand1 > operand2) || operand1 == operand2;
                        alu_out = operand1 - operand2;
                    end
                    default:
                        alu_out = 0;
                endcase 
            7'b1101111: //JUMP. Unconditional
                branch_taken = 1;
            7'b0000011: //LOAD. We calculate here the memory address
                alu_out = operand1 + immediate;
            7'b0100011: //STORE.
                alu_out = operand1 + immediate;
            default: 
                alu_out = 0;
        endcase
    end

endmodule
