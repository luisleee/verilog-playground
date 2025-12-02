`timescale 1ns/1ps

module tb_d_ff();
    reg clk;
    reg rst_n;
    reg d;
    wire q;
    
    // 实例化D触发器
    d_ff u_d_ff (
        .clk(clk),
        .rst_n(rst_n),
        .d(d),
        .q(q)
    );
    
    // 时钟生成，周期20ns（频率50MHz）
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // 测试序列
    initial begin
        // 初始化
        rst_n = 0;
        d = 0;
        
        // 测试1：复位测试
        #15;
        if (q !== 1'b0) $display("Error: Reset test failed at time %0t", $time);
        else $display("Reset test passed");
        
        // 释放复位
        rst_n = 1;
        #5;
        
        // 测试2：正常数据输入测试
        d = 1;
        #20;  // 等待一个时钟周期
        if (q !== 1'b1) $display("Error: D=1 test failed at time %0t", $time);
        else $display("D=1 test passed");
        
        d = 0;
        #20;
        if (q !== 1'b0) $display("Error: D=0 test failed at time %0t", $time);
        else $display("D=0 test passed");
        
        // 测试3：异步复位测试（在时钟上升沿之间）
        d = 1;
        #5;
        rst_n = 0;  // 异步复位
        #2;
        if (q !== 1'b0) $display("Error: Async reset test failed at time %0t", $time);
        else $display("Async reset test passed");
        
        rst_n = 1;
        #18;
        
        // 测试4：多次数据变化测试
        repeat (5) begin
            d = $random;
            #20;
            $display("Time %0t: D=%b, Q=%b", $time, d, q);
        end
        
        // 结束测试
        #100;
        $display("All D flip-flop tests completed");
        $finish;
    end
    
    initial begin
        $dumpfile("d_ff_wave.vcd");
        $dumpvars(0, tb_d_ff);
    end
    
endmodule