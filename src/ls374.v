module ls374 #(parameter WIDTH = 8) (
    input wire clk,
    input wire oe_n,
    input wire [WIDTH-1:0] d,
    output wire [WIDTH-1:0] q
);
reg [WIDTH-1:0] q_reg;

always @(posedge clk) begin
    q_reg <= d;
end

assign q = (oe_n == 1'b0) ? q_reg : {WIDTH{1'bz}};

endmodule