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
        branch_taken = 0;
        out_PC = PC + immediate;  
        alu_out = 0;

        case (opcode)
            7'b0110011: begin //ALU OPS
                branch_taken = 0;
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
            end
            7'b0010011: begin //ALU OPS IMMEDIATES
                branch_taken = 0;
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
            end
            7'b0010111: begin //AUIP rd, imm20 -- rd <- PC + imm20 << 12 -- Add upper immediate to PC
                branch_taken = 0;
                alu_out = out_PC;
            end
            7'b0110111: begin //LUI rd, imm20 -- rd <- imm20 << 12 -- Load upper immediate
                branch_taken = 0;
                alu_out = immediate;                
            end
            7'b1100011: begin //Branching
                case (funct3)
                    3'b000: begin //BEQ rs1, rs2, imm7
                        branch_taken = operand1 == operand2;
                        alu_out = operand1 - operand2; //operand1 - operand2 == 0? -> take branch
                    end
                    3'b001: begin //BNE rs1, rs2, imm7
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
            end
            7'b1101111: //JUMP. Unconditional
                branch_taken = 1;
            7'b0000011: begin //LOAD. We calculate here the memory address
                branch_taken = 0;
                alu_out = operand1 + immediate;
            end
            7'b0100011: begin //STORE.
                branch_taken = 0;
                alu_out = operand1 + immediate;
            end
            7'b1110011: begin //SYSTEM
                branch_taken = 0;
                case (funct3)
                    3'b000: //IRET
                        alu_out = 0;
                    3'b001: //MOVRM
                        alu_out = operand1;
                    3'b111: //TLBWRITE
                        alu_out = 0;
                    default:
                        alu_out = 0;
                endcase
            end
            default: begin
                branch_taken = 0;
                alu_out = 0;
            end
        endcase
    end

endmodule
