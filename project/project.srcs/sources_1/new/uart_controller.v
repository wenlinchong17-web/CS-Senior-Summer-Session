`timescale 1ns / 1ps

module uart_controller(
    input  wire        clk,
    input  wire        rst_n,
    
    // CPU 总线接口
    input  wire        we_i,       // 写使能
    input  wire [31:0] addr_i,     // 地址
    input  wire [31:0] wdata_i,    // CPU写进来的数据
    output reg  [31:0] rdata_o,    // 返回给CPU的数据
    
    // 物理引脚 (连到精工板)
    input  wire        rx,
    output wire        tx
);

    // 内部信号连线
    wire       tx_busy;
    wire [7:0] rx_data;
    wire       rx_done;
    
    // CPU 往 0x8000_0000 写数据，且 we 为 1 时，触发发送
    wire tx_en = (we_i && addr_i == 32'h8000_0000) ? 1'b1 : 1'b0;

    // 例化你之前写的发送模块
    uart_tx u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_en(tx_en),
        .data_in(wdata_i[7:0]), // 取低 8 位发送
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // 例化你之前写的接收模块
    uart_rx u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data_out(rx_data),
        .rx_done(rx_done)
    );

    // CPU 读寄存器逻辑 (地址译码)
    always @(*) begin
        if (addr_i == 32'h8000_0000) begin
            // 读数据寄存器：返回接收到的 8 位数据
            rdata_o = {24'd0, rx_data};
        end 
        else if (addr_i == 32'h8000_0004) begin
            // 读状态寄存器：返回 {30位0, rx_done, tx_busy}
            rdata_o = {30'd0, rx_done, tx_busy};
        end
        else begin
            rdata_o = 32'd0;
        end
    end

endmodule
