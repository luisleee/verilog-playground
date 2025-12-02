module shift_register #(parameter WIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire [1:0] mode,
    input wire si,
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] q,
    output wire so_left,
    output wire so_right
);
assign so_left = q[WIDTH-1];
assign so_right = q[0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        q <= {WIDTH{1'b0}};
    end else begin
        case (mode)
            2'b00: q <= q;
            2'b01: q <= {q[WIDTH-2:0], si};
            2'b10: q <= {si, q[WIDTH-1:1]};
            2'b11: q <= din;
            default: q <= q;
        endcase
    end
end

endmodule