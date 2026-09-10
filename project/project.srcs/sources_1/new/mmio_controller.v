`timescale 1ns / 1ps

module mmio_controller(
    input  wire        clk,
    input  wire        rst_n,
    
    // CPU 总线接口
    input  wire        we_i,       
    input  wire [31:0] addr_i,     
    input  wire [31:0] wdata_i,    
    output reg  [31:0] rdata_o,    
    
    // 物理外设引脚 (连到精工板)
    input  wire        rx,
    output wire        tx,
    output reg  [7:0]  led,        // 新增：8个LED灯
    input  wire [7:0]  switch      // 新增：8个拨码开关
);

    wire       tx_busy;
    wire [7:0] rx_data;
    wire       rx_done;
    
    // 地址分配 (基址 0x8000_0000)
    // 0x00: UART 数据读写
    // 0x04: UART 状态读
    // 0x08: LED 灯写
    // 0x0C: 拨码开关读

    wire uart_tx_en = (we_i && addr_i == 32'h8000_0000) ? 1'b1 : 1'b0;

    // 例化串口发送和接收
    uart_tx u_tx (.clk(clk), .rst_n(rst_n), .tx_en(uart_tx_en), .data_in(wdata_i[7:0]), .tx(tx), .tx_busy(tx_busy));
    uart_rx u_rx (.clk(clk), .rst_n(rst_n), .rx(rx), .data_out(rx_data), .rx_done(rx_done));

    // 写 LED 寄存器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led <= 8'b0;
        end else if (we_i && addr_i == 32'h8000_0008) begin
            led <= wdata_i[7:0]; // CPU写数据到LED
        end
    end

    // CPU 读寄存器逻辑 (地址译码多路选择器)
    always @(*) begin
        case (addr_i)
            32'h8000_0000: rdata_o = {24'd0, rx_data};           // 读串口数据
            32'h8000_0004: rdata_o = {30'd0, rx_done, tx_busy};  // 读串口状态
            32'h8000_000C: rdata_o = {24'd0, switch};            // 读拨码开关
            default:       rdata_o = 32'd0;
        endcase
    end

endmodule