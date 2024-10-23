module alu (
    input CLK,
    input [2:0] funct3,
    input [6:0] funct7,
    input [31:0] operand1,
    input [31:0] operand2,
    output [31:0] aluOut,
    output zero
);

    //always @(posedge CLK) begin
        //case (funct3) 
         //   3'b000: begin
           //     aluOut <= operand1 + operand2; 
          //  end
       // endcase
    //end

    assign aluOut = (funct3 == 3'b000) ? operand1 + operand2 : 32'hFFFFFFFF;
    assign zero = (aluOut == 0);



endmodule
