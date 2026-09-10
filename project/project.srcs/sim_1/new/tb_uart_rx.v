`timescale 1ns / 1ps

module tb_uart_rx();

    reg clk;
    reg rst_n;
    reg rx;             // 模拟电脑发过来的线
    
    wire [7:0] data_out;
    wire rx_done;

    // 例化接收模块
    uart_rx uut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data_out(data_out),
        .rx_done(rx_done)
    );

    // 产生50MHz时钟 (20ns周期)
    always #10 clk = ~clk;

    // 模拟电脑按照115200波特率发送一个字节的任务 (1个bit = 8680ns)
    task send_byte;
        input [7:0] byte_to_send;
        integer i;
        begin
            // 1. 发送起始位 (0)
            rx = 0;
            #8680;
            
            // 2. 发送8位数据位 (低位先发)
            for (i = 0; i < 8; i = i + 1) begin
                rx = byte_to_send[i];
                #8680;
            end
            
            // 3. 发送停止位 (1)
            rx = 1;
            #8680;
        end
    endtask

    initial begin
        // 初始化信号
        clk = 0;
        rst_n = 0;
        rx = 1; // 串口线默认是高电平
        
        #100;
        rst_n = 1; // 撤销复位
        #1000;
        
        // 模拟电脑向FPGA发送十六进制 0x55 (二进制 0101_0101，波形看起来像心跳)
        send_byte(8'h55);
        
        #5000;
        
        // 模拟电脑向FPGA发送十六进制 0x41 (字母 'A')
        send_byte(8'h41);
        
        #5000;
        $stop; // 停止仿真
    end
endmodule