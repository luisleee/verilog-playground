`timescale 1ns/1ps

module tb_jk_ff_async();
    reg clk;
    reg rst_n;
    reg set_n;
    reg j;
    reg k;
    wire q;
    wire q_n;
    
    // 实例化JK触发器
    jk_ff_async u_jk_ff (
        .clk(clk),
        .rst_n(rst_n),
        .set_n(set_n),
        .j(j),
        .k(k),
        .q(q),
        .q_n(q_n)
    );
    
    // 时钟生成，周期20ns（频率50MHz）
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // 测试序列
    initial begin
        // 初始化所有信号
        rst_n = 1;
        set_n = 1;
        j = 0;
        k = 0;
        
        // 测试1：异步复位测试
        #5;
        rst_n = 0;
        #15;
        if (q !== 1'b0 && q_n !== 1'b1) 
            $display("Error: Reset test failed at time %0t", $time);
        else $display("Reset test passed: Q=%b, Q_n=%b", q, q_n);
        
        rst_n = 1;
        #20;
        
        // 测试2：异步置位测试
        set_n = 0;
        #15;
        if (q !== 1'b1 && q_n !== 1'b0)
            $display("Error: Set test failed at time %0t", $time);
        else $display("Set test passed: Q=%b, Q_n=%b", q, q_n);
        
        set_n = 1;
        #20;
        
        // 测试3：JK功能测试
        // JK=00：保持
        j = 0; k = 0;
        #20;
        if (q !== 1'b1) $display("Error: Hold test failed at time %0t", $time);
        else $display("Hold test passed");
        
        // JK=01：复位（Q=0）
        j = 0; k = 1;
        #20;
        if (q !== 1'b0) $display("Error: Reset (JK=01) test failed at time %0t", $time);
        else $display("Reset (JK=01) test passed");
        
        // JK=10：置位（Q=1）
        j = 1; k = 0;
        #20;
        if (q !== 1'b1) $display("Error: Set (JK=10) test failed at time %0t", $time);
        else $display("Set (JK=10) test passed");
        
        // JK=11：翻转
        j = 1; k = 1;
        #20;
        if (q !== 1'b0) $display("Error: Toggle 1 test failed at time %0t", $time);
        else $display("Toggle 1 test passed");
        
        #20;
        if (q !== 1'b1) $display("Error: Toggle 2 test failed at time %0t", $time);
        else $display("Toggle 2 test passed");
        
        // 测试4：优先级测试（复位优先于置位）
        j = 1; k = 1;
        #5;
        rst_n = 0;
        set_n = 0;  // 同时激活复位和置位
        #2;
        if (q !== 1'b0) $display("Error: Reset priority test failed at time %0t", $time);
        else $display("Reset priority test passed");
        
        rst_n = 1;
        set_n = 1;
        #13;
        
        // 测试5：随机测试
        $display("\nRandom test sequence:");
        repeat (8) begin
            j = $random;
            k = $random;
            rst_n = $random & 1;
            set_n = $random & 1;
            #20;
            $display("Time %0t: J=%b, K=%b, RST=%b, SET=%b, Q=%b, Q_n=%b", 
                     $time, j, k, rst_n, set_n, q, q_n);
            
            // 检查Q和Q_n是否互补（除非处于亚稳态）
            if (!(!rst_n || !set_n)) begin
                if (q === ~q_n) 
                    $display("  Q and Q_n are complementary - OK");
                else
                    $display("  Warning: Q and Q_n are not complementary!");
            end
        end
        
        // 结束测试
        #100;
        $display("\nAll JK flip-flop tests completed");
        $finish;
    end
    
    // 监视器，用于监测重要信号变化
    initial begin
        $monitor("Time %0t: CLK=%b, RST=%b, SET=%b, J=%b, K=%b, Q=%b, Q_n=%b",
                 $time, clk, rst_n, set_n, j, k, q, q_n);
    end
    
    initial begin
        $dumpfile("jk_ff_wave.vcd");
        $dumpvars(0, tb_jk_ff_async);
    end
    
endmodule