module hc595(input ser, input srclk, input rclk, input srclr_n, input oe_n, output [7:0] Q);
    reg [7:0] sr;
    reg [7:0] storage;

    always @(posedge srclk or negedge srclr_n) begin
        if (!srclr_n) sr <= 8'b0;
        else sr <= {sr[6:0], ser};
    end

    always @(posedge rclk or negedge srclr_n) begin
        if (!srclr_n) storage <= 8'b0;
        else storage <= sr;
    end

    assign Q = oe_n ? 8'b0 : storage;
endmodule