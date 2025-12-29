`timescale 1ns/1ps

module fifo_tb();

// 时钟和复位信号
reg clk;
reg rst_n;

// FIFO接口信号
reg input_valid;
wire input_enable;
wire output_valid;
reg output_enable;
reg [15:0] data_in;
wire [7:0] data_out;

reg [15:0] d;

// 测试控制
integer write_count = 0;
integer read_count = 0;
integer error_count = 0;

// 预期数据队列
reg [15:0] expected_data_queue [0:15];
integer expected_write_ptr = 0;
integer expected_read_ptr = 0;

// 读取状态
reg reading_low_byte = 0;
reg [7:0] expected_low_byte = 0;

// 实例化FIFO模块
fifo uut (
    .clk(clk),
    .rst_n(rst_n),
    .input_valid(input_valid),
    .input_enable(input_enable),
    .output_valid(output_valid),
    .output_enable(output_enable),
    .data_in(data_in),
    .data_out(data_out),
    .d(d)
);

// 时钟生成：100MHz
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// 复位生成
initial begin
    rst_n = 0;
    #20 rst_n = 1;
end

// 主测试程序
initial begin
    // 初始化信号
    input_valid = 0;
    output_enable = 0;
    data_in = 16'h0000;
    
    // 等待复位完成
    wait(rst_n == 1);
    @(posedge clk); // 等待一个时钟沿
    #1; // 稍微延迟避免竞争
    
    $display("========== FIFO Test Start ==========");
    
    // 测试1: 写入数据直到FIFO满
    $display("\nTest 1: Write data until FIFO is full");
    test_write_full();
    
    // 测试2: 从满的FIFO读取所有数据
    $display("\nTest 2: Read data from full FIFO");
    test_read_all();
    
    // 测试3: 同时读写测试
    $display("\nTest 3: Simultaneous read and write test");
    test_simultaneous_rw();
    
    // 测试4: 边界条件测试
    $display("\nTest 4: Boundary condition test");
    test_boundary();
    
    // 显示测试结果
    $display("\n========== Test Summary ==========");
    $display("Total writes: %0d words", write_count);
    $display("Total reads: %0d bytes", read_count);
    $display("Errors: %0d", error_count);
    
    if (error_count == 0) begin
        $display("All tests PASSED!");
    end else begin
        $display("Test FAILED with %0d errors!", error_count);
    end
    
    #100;
    $finish;
end

// 任务：写入数据直到FIFO满
task test_write_full;
    integer i;
    begin
        for (i = 0; i < 16; i = i + 1) begin
            // 准备数据：16位数据，低字节=序号，高字节=序号+100
            data_in = {8'(i+100), 8'(i)};
            
            // 在时钟上升沿前设置输入有效

            input_valid = 1;
            
            // 等待FIFO准备好接收数据（input_enable为高）
            wait(input_enable == 1);
            
            // 等待下一个时钟上升沿，数据应该被写入
            @(posedge clk);
            #1;
            $display("Time %0t: Write data[%0d] = 0x%04h", $time, i, data_in);
            write_count = write_count + 1;
            
            // 保存预期数据
            expected_data_queue[expected_write_ptr] = data_in;
            expected_write_ptr = (expected_write_ptr + 1) % 16;
        end
        
        // 写入完成后关闭input_valid
        @(posedge clk);
        #1;
        input_valid = 0;
        
        #40; // 等待一段时间
    end
endtask

// 任务：读取所有数据
task test_read_all;
    integer i;
    reg [7:0] expected_byte;
    reg is_low_byte;
    begin
        output_enable = 1;
        reading_low_byte = 0;
        
        // 读取32个字节（16个字 * 2字节/字）
        for (i = 0; i < 32; i = i + 1) begin
            // 等待output_valid变高（表示有数据可读）
            if (!output_valid) begin
                @(posedge output_valid); // 等待output_valid变高
            end
            
            // 在时钟上升沿采样数据
            @(posedge clk);
            #1;
            
            // 确定当前应该读取的是低字节还是高字节
            is_low_byte = (i % 2 == 0);
            
            if (is_low_byte) begin
                // 低字节：预期数据队列中当前字的低8位
                expected_byte = expected_data_queue[expected_read_ptr][7:0];
                expected_low_byte = expected_byte; // 保存用于调试
            end else begin
                // 高字节：预期数据队列中当前字的高8位
                expected_byte = expected_data_queue[expected_read_ptr][15:8];
            end
            
            // 检查数据
            if (data_out !== expected_byte) begin
                $display("ERROR: Time %0t: Byte[%0d] = 0x%02h, expected 0x%02h (Word[%0d], %s byte)", 
                         $time, i, data_out, expected_byte, expected_read_ptr,
                         is_low_byte ? "low" : "high");
                error_count = error_count + 1;
            end else begin
                $display("Time %0t: Byte[%0d] = 0x%02h (OK) - Word[%0d], %s byte", 
                         $time, i, data_out, expected_read_ptr,
                         is_low_byte ? "low" : "high");
            end
            
            read_count = read_count + 1;
            
            // 如果刚刚读取了高字节，移动到下一个字
            if (!is_low_byte) begin
                expected_read_ptr = (expected_read_ptr + 1) % 16;
            end
            
            #1;
        end
        
        output_enable = 0;
        #20;
    end
endtask

// 任务：同时读写测试
task test_simultaneous_rw;
    integer i, bytes_to_read;
    reg [15:0] test_data;
    begin
        $display("\nStarting simultaneous read/write test...");
        
        // 重置预期队列指针
        expected_write_ptr = 0;
        expected_read_ptr = 0;
        
        // 清除队列
        for (i = 0; i < 16; i = i + 1) begin
            expected_data_queue[i] = 16'h0000;
        end
        
        // 启动写入线程
        fork
            begin: write_thread
                for (i = 0; i < 8; i = i + 1) begin
                    test_data = {8'(i+200), 8'(i+50)};
                    
                    // 等待FIFO不满
                    wait(input_enable == 1);
                    
                    input_valid = 1;
                    data_in = test_data;
                    
                    @(posedge clk);
                    #1;
                    $display("Time %0t: Simul write[%0d] = 0x%04h", $time, i, data_in);
                    write_count = write_count + 1;
                    
                    // 保存预期数据
                    expected_data_queue[expected_write_ptr] = test_data;
                    expected_write_ptr = (expected_write_ptr + 1) % 16;
                    
                    input_valid = 0;
                    
                    // 随机延迟1-3个时钟周期
                    repeat($urandom_range(1,3)) @(posedge clk);
                end
            end
            
            begin: read_thread
                output_enable = 1;
                bytes_to_read = 0;
                
                // 等待一些数据写入
                repeat(3) @(posedge clk);
                
                // 读取数据直到读到16个字节
                while (bytes_to_read < 16) begin
                    if (output_valid) begin
                        $display("Time %0t: Simul read byte[%0d] = 0x%02h", 
                                 $time, bytes_to_read, data_out);
                        read_count = read_count + 1;
                        bytes_to_read = bytes_to_read + 1;
                    end
                    @(posedge clk);
                    #1;
                end
                output_enable = 0;
            end
        join
        
        #50;
    end
endtask

// 任务：边界条件测试
task test_boundary;
    reg [15:0] test_data;
    begin
        $display("\nTesting boundary conditions...");
        
        // 清空FIFO
        wait_for_fifo_empty();
        
        // 测试1: 在FIFO空时尝试读取
        $display("\n1. Try to read from empty FIFO:");
        @(posedge clk);
        #1;
        output_enable = 1;
        
        // 检查几个时钟周期
        repeat(3) begin
            @(posedge clk);
            #1;
            if (output_valid == 0) begin
                $display("  Time %0t: output_valid=0 (FIFO empty)", $time);
            end else begin
                $display("  ERROR: Time %0t: output_valid should be 0 when FIFO empty", $time);
                error_count = error_count + 1;
            end
        end
        
        output_enable = 0;
        
        // 测试2: 写入一个数据然后读取
        rst_n=0;
        @(posedge clk); // 等待一个时钟沿
        rst_n=1;
        wait(rst_n == 1);
        @(posedge clk); // 等待一个时钟沿
        #1; // 稍微延迟避免竞争

        $display("\n2. Write one word and read both bytes:");
        test_data = 16'hA5A5;
        
        // 写入数据
        @(posedge clk);
        #1;
        input_valid = 1;
        data_in = test_data;
        
        wait(input_enable == 1);
        
        $display("  Write: 0x%04h", data_in);
        write_count = write_count + 1;
        
        @(posedge clk);
        #1;

        input_valid = 0;

        
        // 等待数据可用
        wait(output_valid == 1);
        
        // 读取两个字节
        output_enable = 1;
        
        // 读取低字节
        @(posedge clk);
        #1;
        if (data_out == 8'hA5) begin
            $display("  Read low byte: 0x%02h (OK)", data_out);
        end else begin
            $display("  ERROR: Read low byte: 0x%02h, expected 0xA5", data_out);
            error_count = error_count + 1;
        end
        read_count = read_count + 1;
        
        // 读取高字节
        @(posedge clk);
        #1;
        if (data_out == 8'hA5) begin
            $display("  Read high byte: 0x%02h (OK)", data_out);
        end else begin
            $display("  ERROR: Read high byte: 0x%02h, expected 0xA5", data_out);
            error_count = error_count + 1;
        end
        read_count = read_count + 1;
        
        output_enable = 0;
        
        #20;
    end
endtask

// 辅助任务：等待FIFO为空
task wait_for_fifo_empty;
    begin
        // 持续读取直到FIFO为空
        output_enable = 1;
        while (output_valid) begin
            @(posedge clk);
            #1;
        end
        output_enable = 0;
        @(posedge clk);
        #1;
    end
endtask

// 监控关键信号
initial begin
    forever begin
        @(posedge clk);
        #1;
        if (input_valid && input_enable) begin
            $display("MONITOR: Time %0t: WRITE data_in=0x%04h", $time, data_in);
        end
        if (output_enable && output_valid) begin
            $display("MONITOR: Time %0t: READ data_out=0x%02h", $time, data_out);
        end
    end
end

// 生成波形文件
initial begin
    $dumpfile("fifo_tb.vcd");
    $dumpvars(0, fifo_tb);
end

endmodule