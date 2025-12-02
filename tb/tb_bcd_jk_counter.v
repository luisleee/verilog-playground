`timescale 1ns/1ps

module tb_bcd_jk_counter();
    reg clk;
    reg rst;
    wire [3:0] q;
    
    // 实例化计数器
    bcd_jk_counter u_counter(clk, rst, q);
    
    // 生成时钟
    always #10 clk = ~clk;
    
    initial begin
        // 初始化
        clk = 0;
        rst = 1;
        
        // 生成波形文件
        $dumpfile("bcd_counter_wave.vcd");
        $dumpvars(0, tb_bcd_jk_counter);
        
        $display("=== BCD计数器测试开始 ===");
        
        // 测试1: 复位测试
        #20;
        rst = 0;
        $display("复位释放, 当前计数: %d", q);
        
        // 测试2: 计数0-9
        #20; $display("计数: %d", q);
        #20; $display("计数: %d", q);
        #20; $display("计数: %d", q);
        #20; $display("计数: %d", q);
        #20; $display("计数: %d", q);
        #20; $display("计数: %d", q);
        #20; $display("计数: %d", q);
        #20; $display("计数: %d", q);
        #20; $display("计数: %d", q);
        
        // 测试3: 9->0
        #20; $display("计数: %d (应该为0)", q);
        
        // 测试4: 继续计数
        #20; $display("计数: %d", q);
        #20; $display("计数: %d", q);
        
        // 测试5: 中途复位
        #20;
        rst = 1;
        $display("复位, 计数: %d (应该为0)", q);
        
        #20;
        rst = 0;
        $display("复位释放, 重新计数: %d", q);
        
        // 测试6: 再运行几个周期
        repeat(5) begin
            #20;
            $display("计数: %d", q);
        end
        
        $display("=== 测试完成 ===");
        #100;
        $finish;
    end
    
endmodule