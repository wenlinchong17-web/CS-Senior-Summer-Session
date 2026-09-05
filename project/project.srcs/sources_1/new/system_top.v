`timescale 1ns / 1ps

module system_top(
    input wire clk,       // 精工板时钟
    input wire rst_n,     // 精工板复位键 (低有效)
    input wire rx,        // 串口接收引脚
    output wire tx        // 串口发送引脚
);

    // 内部总线连线
    wire        mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;
    
    // CPU 例化
    cpu_top u_cpu (
        .clk        (clk),
        .rst        (~rst_n),      // 队友的 CPU 可能是高电平复位，这里取反
        .mem_we_o   (mem_we),
        .mem_addr_o (mem_addr),
        .mem_wdata_o(mem_wdata),
        .mem_rdata_i(mem_rdata),
        
        // 调试信号先悬空或接 wire (这里为了简洁省略，实际可接入 ILA)
        .dbg_pc() // 其他 dbg_ 信号同理不一一列出
    );

    // ==========================================
    // 交通警察 (Address Decoder)
    // 规定：地址最高位是 8 (0x8000_XXXX)，属于 UART
    //       地址最高位是 0 (0x0000_XXXX)，属于 RAM
    // ==========================================
    wire is_uart = (mem_addr[31:28] == 4'h8); 
    wire is_ram  = (mem_addr[31:28] == 4'h0);
    
    wire uart_we = mem_we & is_uart;
    wire ram_we  = mem_we & is_ram;
    
    wire [31:0] uart_rdata;
    wire [31:0] ram_rdata;
    
    // 数据多路选择器：谁的地址被访问，就把谁的数据传给 CPU
    assign mem_rdata = is_uart ? uart_rdata : 
                       is_ram  ? ram_rdata : 32'd0;

    // 例化数据内存 (原先在 CPU 肚子里的那个)
    dmem u_dmem (
        .clk  (clk),
        .we   (ram_we),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .rdata(ram_rdata)
    );

    // 例化你的 UART 控制器
    uart_controller u_uart (
        .clk    (clk),
        .rst_n  (rst_n),
        .we_i   (uart_we),
        .addr_i (mem_addr),
        .wdata_i(mem_wdata),
        .rdata_o(uart_rdata),
        .rx     (rx),
        .tx     (tx)
    );

endmodule