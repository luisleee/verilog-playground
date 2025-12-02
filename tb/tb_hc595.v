`timescale 1ns/1ps

module tb_hc595();
    // 输入信号
    reg ser;          // 串行数据输入
    reg srclk;        // 移位寄存器时钟
    reg rclk;         // 存储寄存器时钟
    reg srclr_n;      // 移位寄存器清零
    reg oe_n;         // 输出使能
    
    // 输出信号
    wire [7:0] Q;     // 并行输出
    
    // 实例化被测模块
    hc595 u_hc595 (
        .ser(ser),
        .srclk(srclk),
        .rclk(rclk),
        .srclr_n(srclr_n),
        .oe_n(oe_n),
        .Q(Q)
    );
    
    // 时钟生成
    initial begin
        srclk = 0;
        forever #25 srclk = ~srclk;  // 20MHz
    end
    
    // 主测试
    initial begin
        // 初始化
        initialize();
        
        $display("========== HC595 简单测试开始 ==========");
        
        // 测试1: 复位测试
        test_reset();
        
        // 测试2: 基本移位测试
        test_shift_basic();
        
        // 测试3: 输出使能测试
        test_output_enable();
        
        // 测试4: 综合测试
        test_comprehensive();
        
        $display("========== HC595 简单测试完成 ==========");
        #100;
        $finish;
    end
    
    // 初始化任务
    task initialize;
    begin
        ser = 0;
        srclk = 0;
        rclk = 0;
        srclr_n = 1;
        oe_n = 1;  // 初始禁用输出
        #100;
    end
    endtask
    
    // 测试1: 复位功能
    task test_reset;
    begin
        $display("[测试1] 复位功能测试");
        
        // 先移入一些数据
        oe_n = 0;
        shift_in_byte(8'b10101010);
        pulse_rclk();
        $display("  移入数据: 10101010, 输出: %b", Q);
        
        // 测试移位寄存器复位
        srclr_n = 0;
        #50;
        if (u_hc595.sr === 8'b0)
            $display("  ✓ 移位寄存器复位成功");
        else
            $display("  ✗ 移位寄存器复位失败");
        
        srclr_n = 1;
        #50;
        
        // 移入新数据并复位
        shift_in_byte(8'b11001100);
        pulse_rclk();
        srclr_n = 0;
        #50;
        pulse_rclk();  // 复位信号传播到存储寄存器
        
        if (Q === 8'b0)
            $display("  ✓ 存储寄存器复位成功");
        else
            $display("  ✗ 存储寄存器复位失败");
        
        srclr_n = 1;
        #100;
    end
    endtask
    
    // 测试2: 基本移位功能
    task test_shift_basic;
    begin
        $display("[测试2] 基本移位功能测试");
        oe_n = 0;
        
        // 测试数据1
        shift_in_byte(8'b10010110);
        pulse_rclk();
        
        if (Q === 8'b10010110)
            $display("  ✓ 数据 10010110 移位成功");
        else
            $display("  ✗ 数据 10010110 移位失败，输出: %b", Q);
        
        // 测试数据2
        shift_in_byte(8'b01101001);
        pulse_rclk();
        
        if (Q === 8'b01101001)
            $display("  ✓ 数据 01101001 移位成功");
        else
            $display("  ✗ 数据 01101001 移位失败，输出: %b", Q);
        
        #100;
    end
    endtask
    
    // 测试3: 输出使能
    task test_output_enable;
    begin
        $display("[测试3] 输出使能测试");
        
        // 移入数据
        shift_in_byte(8'b11110000);
        pulse_rclk();
        
        // 测试输出使能有效
        oe_n = 0;
        #20;
        if (Q === 8'b11110000)
            $display("  ✓ 输出使能有效时输出正确");
        else
            $display("  ✗ 输出使能有效时输出错误: %b", Q);
        
        // 测试输出使能无效
        oe_n = 1;
        #20;
        if (Q === 8'b0)
            $display("  ✓ 输出使能无效时输出为0");
        else
            $display("  ✗ 输出使能无效时输出不为0: %b", Q);
        
        oe_n = 0;
        #100;
    end
    endtask
    
    // 测试4: 综合测试
    task test_comprehensive;
        integer i;
        reg [7:0] test_data;
    begin
        $display("[测试4] 综合测试");
        
        // 测试几个特定模式
        test_patterns(8'b00000001, "单比特模式");
        test_patterns(8'b10000000, "最高位模式");
        test_patterns(8'b10101010, "交替模式");
        test_patterns(8'b11111111, "全1模式");
        test_patterns(8'b00000000, "全0模式");
        
        // 随机测试5次
        $display("  随机测试:");
        for (i = 0; i < 5; i = i + 1) begin
            test_data = $random;
            shift_in_byte(test_data);
            pulse_rclk();
            
            if (Q === test_data)
                $display("    ✓ 随机测试%d: %b", i, test_data);
            else
                $display("    ✗ 随机测试%d失败: 期望=%b, 实际=%b", 
                        i, test_data, Q);
            #50;
        end
    end
    endtask
    
    // 辅助任务：测试特定模式
    task test_patterns;
        input [7:0] data;
        input string pattern_name;
    begin
        shift_in_byte(data);
        pulse_rclk();
        
        if (Q === data)
            $display("  ✓ %s 测试通过", pattern_name);
        else
            $display("  ✗ %s 测试失败: 期望=%b, 实际=%b", 
                    pattern_name, data, Q);
        #50;
    end
    endtask
    
    // 辅助任务：移入一个字节
    task shift_in_byte;
        input [7:0] data;
        integer i;
    begin
        for (i = 7; i >= 0; i = i - 1) begin
            ser = data[i];
            @(negedge srclk);  // 在时钟下降沿准备数据
            @(posedge srclk);  // 在上升沿移入数据
            #5;
        end
    end
    endtask
    
    // 辅助任务：产生rclk脉冲
    task pulse_rclk;
    begin
        @(negedge srclk);
        rclk = 1;
        #40;
        rclk = 0;
        #10;
    end
    endtask
    
    // 生成VCD波形文件
    initial begin
        $dumpfile("hc595.vcd");
        $dumpvars(0, tb_hc595);  // 记录所有信号
    end
    
    // 可选：添加监控
    initial begin
        $monitor("Time %0t: SER=%b, SRCLK=%b, RCLK=%b, OE_N=%b, Q=%b", 
                 $time, ser, srclk, rclk, oe_n, Q);
    end
    
endmodule