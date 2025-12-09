module counter60 (
    input wire clk, rst,
    input wire key,
    output wire [8:0] segment_led_1, segment_led_2
);

reg [23:0] cnt;
reg running;
reg [5:0] seconds;
reg [3:0] sec_ones, sec_tens;


parameter CLK_FREQ = 24'd12_000_000;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt <= 24'd0;
        running <= 1'b0;
        seconds <= 6'd0;
    end else if (key) begin
        running <= ~running;
    end else if (running) begin
        if (cnt == CLK_FREQ - 1) begin
            cnt <= 24'd0;
            if (seconds == 6'd59) begin
                seconds <= 6'd0;
            end else begin
                seconds <= seconds + 1'b1;
            end
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
end

always @* begin
    sec_ones = seconds % 10;
    sec_tens = seconds / 10;
end

segment7 seg1 (.bcd(sec_ones), .seg(segment_led_1));
segment7 seg2 (.bcd(sec_tens), .seg(segment_led_2));

endmodule

module segment7 (
    input wire [3:0] bcd,
    output reg [8:0] seg
);

always @* begin
    case (bcd)
        4'd0: seg = 9'b0000_0011_1;
        4'd1: seg = 9'b1001_1111_1;
        4'd2: seg = 9'b0010_0101_1;
        4'd3: seg = 9'b0000_1101_1;
        4'd4: seg = 9'b1001_1001_1;
        4'd5: seg = 9'b0100_1001_1;
        4'd6: seg = 9'b0100_0001_1;
        4'd7: seg = 9'b0001_1111_1;
        4'd8: seg = 9'b0000_0001_1;
        4'd9: seg = 9'b0000_1001_1;
        default: seg = 9'b1111_1111_1;
    endcase
end

endmodule