
module jk_ff_async (
    input wire clk,
    input wire rst_n,
    input wire set_n,
    input wire j,
    input wire k,
    output reg q,
    output reg q_n
);

always @(negedge clk or negedge rst_n or negedge set_n) begin
    if (!rst_n) begin
        q <= 1'b0;
        q_n <= 1'b1;
    end else if (!set_n) begin
        q <= 1'b1;
        q_n <= 1'b0;
    end else begin
        case ({j, k})
            2'b00: begin
                q <= q;
                q_n <= q_n;
            end
            2'b01: begin
                q <= 1'b0;
                q_n <= 1'b1;
            end
            2'b10: begin
                q <= 1'b1;
                q_n <= 1'b0;
            end
            2'b11: begin
                q <= ~q;
                q_n <= ~q_n;
            end
        endcase
    end
end

endmodule