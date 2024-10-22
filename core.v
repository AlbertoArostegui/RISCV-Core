module core (
    input CLK,
    input RESET,
    output [3:0] out
);
    reg [3:0] aux = 0;
    always @(posedge CLK, RESET) begin
        if (RESET) begin
            aux <= 4'b0;
        end else begin
            aux <= out + 1;
        end
    end

    assign out = aux;

endmodule
