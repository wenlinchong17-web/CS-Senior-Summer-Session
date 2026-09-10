`timescale 1ns / 1ps

// 板上晶振按 100 MHz（精工 Artix-7，T5）。仿真 tb_uart 仍用模块默认 50 MHz。
// 若 115200 仍对不齐，把 CLK_FREQ 改回 50_000_000，XDC 周期改回 20 ns。
module system_top (
    input  wire clk,
    input  wire rst_n,
    input  wire rx,
    output wire tx
);

    wire        mem_we;
    wire        mem_re;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;

    cpu_top u_cpu (
        .clk            (clk),
        .rst            (~rst_n),
        .mem_we_o       (mem_we),
        .mem_re_o       (mem_re),
        .mem_addr_o     (mem_addr),
        .mem_wdata_o    (mem_wdata),
        .mem_rdata_i    (mem_rdata),
        .dbg_pc         (),
        .dbg_stall      (),
        .dbg_flush      (),
        .dbg_reg_data   (),
        .dbg_reg_addr   (5'd0),
        .dbg_uaddr      (),
        .dbg_overflow   (),
        .dbg_epc        (),
        .dbg_perf_cycles(),
        .dbg_perf_inst  (),
        .dbg_perf_stall (),
        .dbg_perf_flush ()
    );

    // 0x8xxx_xxxx → UART；0x0xxx_xxxx → RAM
    wire is_uart = (mem_addr[31:28] == 4'h8); 
    wire is_ram  = (mem_addr[31:28] == 4'h0);
    
    wire uart_we = mem_we & is_uart;
    wire uart_re = mem_re & is_uart;
    wire ram_we  = mem_we & is_ram;
    
    wire [31:0] uart_rdata;
    wire [31:0] ram_rdata;
    
    assign mem_rdata = is_uart ? uart_rdata :
                       is_ram  ? ram_rdata : 32'd0;

    dmem u_dmem (
        .clk  (clk),
        .we   (ram_we),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .rdata(ram_rdata)
    );

    uart_controller #(
        .CLK_FREQ(100_000_000),
        .BAUD    (115200),
        .HW_ECHO (0)
    ) u_uart (
        .clk    (clk),
        .rst_n  (rst_n),
        .we_i   (uart_we),
        .re_i   (uart_re),
        .addr_i (mem_addr),
        .wdata_i(mem_wdata),
        .rdata_o(uart_rdata),
        .rx     (rx),
        .tx     (tx)
    );

endmodule