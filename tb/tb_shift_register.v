`timescale 1ns/1ps

module tb_shift_register();
    reg clk, rst_n;
    reg [1:0] mode;
    reg si;
    reg [7:0] din;
    wire [7:0] q;
    wire so_left, so_right;
    
    shift_register u_shift(clk, rst_n, mode, si, din, q, so_left, so_right);
    
    // 时钟
    always #10 clk = ~clk;
    
    initial begin
        // 波形文件
        $dumpfile("shift_register.vcd");
        $dumpvars;
        
        // 初始化
        clk = 0;
        rst_n = 0;
        mode = 0;
        si = 0;
        din = 0;
        
        #20 rst_n = 1;
        
        // 测试1: 保持模式
        mode = 2'b00;
        din = 8'hAA;
        #20 $display("保持模式: q=%b", q);
        
        // 测试2: 左移
        mode = 2'b01;
        si = 1;
        #20 $display("左移1: q=%b, so_left=%b", q, so_left);
        
        // 测试3: 右移
        mode = 2'b10;
        si = 1;
        #20 $display("右移1: q=%b, so_right=%b", q, so_right);
        
        // 测试4: 并行加载
        mode = 2'b11;
        din = 8'h55;
        #20 $display("加载0x55: q=%b", q);
        
        // 测试5: 循环移位测试
        mode = 2'b01;  // 左移
        si = 0;
        repeat(4) begin
            si = ~si;
            #20 $display("左移: q=%b", q);
        end
        
        #100;
        $finish;
    end
    
endmodule