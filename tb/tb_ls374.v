`timescale 1ns/1ps

module tb_ls374();
    reg clk, oe_n;
    reg [7:0] d;
    wire [7:0] q;
    
    ls374 u_dut(.clk(clk), .oe_n(oe_n), .d(d), .q(q));
    
    // 时钟
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        oe_n = 1;
        d = 8'h00;
        
        // 测试序列
        #10 oe_n = 0;
        
        // 测试1: 基本功能
        d = 8'hAA;
        @(posedge clk);
        #1;
        if (q !== 8'hAA) $display("Error 1");
        
        d = 8'h55;
        @(posedge clk);
        #1;
        if (q !== 8'h55) $display("Error 2");
        
        // 测试2: 输出使能
        oe_n = 1;
        #10;
        if (q !== 8'hzz) $display("Error 3");
        
        oe_n = 0;
        #10;
        if (q !== 8'h55) $display("Error 4");
        
        // 测试3: 随机测试
        repeat (10) begin
            d = $random;
            @(posedge clk);
            #1;
            if (q !== d) $display("Error 5");
        end
        
        $display("Simple test completed");
        $finish;
    end

    initial begin
        $dumpfile("ls374.vcd");
        $dumpvars(0, tb_ls374);
    end
endmodule