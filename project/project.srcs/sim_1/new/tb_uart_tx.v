`timescale 1ns / 1ps

module tb_uart_tx();

    reg clk;
    reg rst_n;
    reg tx_en;
    reg [7:0] data_in;
    wire tx;
    wire tx_busy;

    // 把你刚才写的模块拿过来例化(连线)
    uart_tx uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_en(tx_en),
        .data_in(data_in),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // 产生50MHz的模拟时钟
    always #10 clk = ~clk;

    initial begin
        // 初始化信号
        clk = 0;
        rst_n = 0;
        tx_en = 0;
        data_in = 8'h00;

        // 等待100ns后撤销复位
        #100;
        rst_n = 1;
        #100;

        // 模拟CPU：告诉UART，给我发送十六进制数 8'h41 (ASCII码的字母 'A')
        data_in = 8'h41; // 二进制是 0100_0001
        tx_en = 1;       // 拉高使能信号
        #20;             // 保持一个时钟周期
        tx_en = 0;       // 撤销使能信号

        // 等它发完 (大概需要 10个波特率周期)
        wait(tx_busy == 0); 
        
        #1000;
        $stop; // 停止仿真
    end
endmodule