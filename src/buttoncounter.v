module buttoncounter(clk, rst, key, seg_led_1, seg_led_2);
    input clk;
    input rst;
    input key;
    output [7:0] seg_led_1;
    output [7:0] seg_led_2;

    reg [7:0] counter;

    wire key_debounced;
    reg key_debounced_reg;
    wire key_edge;

    wire [3:0] ones, tens;

    wire [7:0] seg_ones, seg_tens;

    debouncer #(.N(1000)) debouncer_inst (
        .clk(clk),
        .sin(key),
        .sout(key_debounced)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            key_debounced_reg <= 1'b1;
        end else begin
            key_debounced_reg <= key_debounced;
        end
    end

    assign key_edge = (key_debounced_reg == 1'b1) && (key_debounced == 1'b0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 8'd0;
        end else if (key_edge) begin
            if (counter == 8'd99) begin
                counter <= 8'd0;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

    assign ones = counter % 10;
    assign tens = counter / 10;

    seg seg_ones_inst (
        .x(ones),
        .s(seg_ones)
    );
    
    seg seg_tens_inst (
        .x(tens),
        .s(seg_tens)
    );

    assign seg_led_1 = seg_ones;
    assign seg_led_2 = seg_tens;

endmodule