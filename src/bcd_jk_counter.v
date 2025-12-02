module jk_ff(input J, input K, input clk, input rst, output reg Q);
    always @(posedge clk or posedge rst) begin
        if (rst) Q <= 1'b0;
        else begin
            case ({J,K})
                2'b00: Q <= Q;
                2'b01: Q <= 1'b0;
                2'b10: Q <= 1'b1;
                2'b11: Q <= ~Q;
            endcase
        end
    end
endmodule

module bcd_jk_counter(input clk, input rst, output [3:0] q);
    wire [3:0] q_int;
    wire [3:0] d;
    wire [3:0] J;
    wire [3:0] K;

    assign d = (q_int == 4'd9) ? 4'd0 : q_int + 4'd1;
    assign J = (~q_int) & d;
    assign K = q_int & (~d);

    jk_ff jk0(J[0], K[0], clk, rst, q_int[0]);
    jk_ff jk1(J[1], K[1], clk, rst, q_int[1]);
    jk_ff jk2(J[2], K[2], clk, rst, q_int[2]);
    jk_ff jk3(J[3], K[3], clk, rst, q_int[3]);

    assign q = q_int;
endmodule

