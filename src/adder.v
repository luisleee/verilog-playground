module add1(input x, input y, input cin, output cout, output sum);
    assign sum = x ^ y ^ cin;
    assign cout = (x & y) | (x & cin) | (y & cin);
endmodule

module add2(input [1:0]x, input [1:0]y, input cin, output cout, output [1:0]sum);
    wire c;
    add1 A1(
        .x(x[0]),
        .y(y[0]),
        .cin(cin),
        .cout(c),
        .sum(sum[0])
    );

    add1 A2(
        .x(x[1]),
        .y(y[1]),
        .cin(c),
        .cout(cout),
        .sum(sum[1])
    );
endmodule

module add4(input [3:0] x, input [3:0] y, input cin, output cout, output [3:0]sum);
    wire c;
    add2 A1(
        .x(x[1:0]),
        .y(y[1:0]),
        .cin(cin),
        .cout(c),
        .sum(sum[1:0])
    );

    add2 A2(
        .x(x[3:2]),
        .y(y[3:2]),
        .cin(c),
        .cout(cout),
        .sum(sum[3:2])
    );
endmodule

module seg(input [3:0] x, output reg [7:0] s);
    always @(*) begin
        case (x)
            0: s = 8'b0011_1111;
            1: s = 8'b0000_0110;
            2: s = 8'b0101_1011;
            3: s = 8'b0100_1111;
            4: s = 8'b0110_0110;
            5: s = 8'b0110_1101;
            6: s = 8'b0111_1101;
            7: s = 8'b0000_0111;
            8: s = 8'b0111_1111;
            9: s = 8'b0110_1111;
            default: s = 8'b0000_0000;
        endcase
    end
endmodule

module twoseg(input [4:0] in, output [7:0] segH, output [7:0] segL);
    wire [3:0] tens, ones;
    assign tens = (in >= 30) ? 4'd3 :
                  (in >= 20) ? 4'd2 :
                  (in >= 10) ? 4'd1 : 4'd0;
    assign ones = in - tens * 4'd10;

    seg s1(tens, segH);
    seg s2(ones, segL);
endmodule


module debouncer #(parameter N = 1000) (input clk, input sin, output reg sout);
    localparam IDLE = 1'b0;
    localparam DEBOUNCE = 1'b1;

    reg state = IDLE;
    reg [$clog2(N)-1:0] counter = 0;
    reg sin_sync = 0;

    always @(posedge clk) begin
        sin_sync <= sin;

        case (state)
            IDLE: begin
                if (sin_sync != sout) begin
                    state <= DEBOUNCE;
                    counter <= 0;
                end
            end
            DEBOUNCE: begin
                if (sin_sync == sout)
                    state <= IDLE;
                else if (counter == N-1) begin
                    sout <= sin_sync;
                    state <= IDLE;
                end else
                    counter <= counter + 1'b1;
            end
        endcase
    end
endmodule

module debouncer4 #(parameter N = 1000) (
    input clk,
    input [3:0] sin,
    output [3:0] sout
);

    genvar i;
    generate
        for (i = 0; i < 4; i = i+1) begin : deb_inst
            debouncer #(.N(N)) u_debouncer (
                .clk(clk),
                .sin(sin[i]),
                .sout(sout[i])
            );
        end
    endgenerate

endmodule


module main(input clk, input [3:0] sws, input [3:0] btns, output [7:0] segH, output [7:0] segL, output [7:0] leds);
    localparam DISPLAY_A = 3'b001;
    localparam DISPLAY_B = 3'b010;
    localparam DISPLAY_S = 3'b100;

    reg readonly = 0;
    reg [2:0] display = DISPLAY_A;

    reg [3: 0] a = 0, b = 0;
    wire [4: 0] s;
    reg [4: 0] toshow;

    // LED state
    assign leds = {readonly, 4'b0000, display};

    // addition
    add4 A(a, b, 1'b0, s[4], s[3:0]);

    // twosegs
    twoseg S(toshow, segH, segL);
    always @(*) begin
        case (display)
            DISPLAY_A: toshow = {1'b0, a};
            DISPLAY_B: toshow = {1'b0, b};
            DISPLAY_S: toshow = s;
            default: toshow = 5'b0;
        endcase
    end

    // write in
    always @(posedge clk) begin
        if (!readonly) begin
            case (display)
                DISPLAY_A: a <= sws;
                DISPLAY_B: b <= sws;
                default: ;
            endcase
        end
    end

    // btn debounce
    wire [3: 0] debounced_btns;
    debouncer4 #(.N(1000)) DB(clk, btns, debounced_btns);

    // switch display
    reg [3:0] btns_last = 0;
    always @(posedge clk) begin
        btns_last <= debounced_btns;

        if (debounced_btns[0] && !btns_last[0]) begin
            readonly <= ~readonly;
        end

        if (debounced_btns[1] && !btns_last[1])
            display <= DISPLAY_A;
        else if (debounced_btns[2] && !btns_last[2])
            display <= DISPLAY_B;
        else if (debounced_btns[3] && !btns_last[3])
            display <= DISPLAY_S;
    end
endmodule