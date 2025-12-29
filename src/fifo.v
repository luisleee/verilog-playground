module fifo(
    input clk,
    input rst_n,
    input input_valid,
    output input_enable,
    output output_valid,
    input output_enable,
    input [15:0] data_in,
    output reg [7:0] data_out,
    output reg [15:0] d
);

reg [15:0] mem [15:0];          // 16个16位存储单元
reg [3:0] write_addr;          // 写地址指针
reg [3:0] read_addr;           // 读地址指针
reg rd_byte_sel;               // 字节选择：0=低字节，1=高字节
reg [4:0] word_count;          // 已存储的字数（16位）

wire fifo_full;
wire fifo_empty;
wire [3:0] next_write_addr;
wire [3:0] next_read_addr;

// 计算下一个地址（环形缓冲区）
assign next_write_addr = (write_addr == 4'd15) ? 4'd0 : write_addr + 1'b1;
assign next_read_addr = (read_addr == 4'd15) ? 4'd0 : read_addr + 1'b1;

always @(*) begin
    d <= mem[9];
end

// 计算FIFO状态
assign fifo_full = (word_count == 5'd16);      // 存满了16个16位字
assign fifo_empty = (word_count == 5'd0);      // 没有数据

// 输出控制信号
assign input_enable = !fifo_full;             // FIFO不满时可以写入
assign output_valid = !fifo_empty;            // FIFO不空时可以读取

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位所有寄存器和存储器
        for (integer i = 0; i < 16; i = i + 1) begin
            mem[i] <= 16'd0;
        end
        
        write_addr   <= 4'd0;
        read_addr    <= 4'd0;
        rd_byte_sel  <= 1'b0;
        word_count   <= 5'd0;
        data_out     <= 8'd0;
    end else begin
        // 写操作：当输入有效且FIFO不满时
        if (input_valid && !fifo_full) begin
            mem[write_addr] <= data_in;
            write_addr <= next_write_addr;
            word_count <= word_count + 1'b1;
        end
        
        // 读操作：当输出使能且FIFO不空时
        if (output_enable && !fifo_empty) begin
            // 每次读取一个字节
            if (rd_byte_sel == 1'b0) begin
                data_out <= mem[read_addr][7:0];      // 低字节
            end else begin
                data_out <= mem[read_addr][15:8];     // 高字节
                // 读取完高字节后，移动到下一个字
                read_addr <= next_read_addr;
                word_count <= word_count - 1'b1;
            end
            
            // 切换字节选择
            rd_byte_sel <= ~rd_byte_sel;
        end
    end
end

endmodule