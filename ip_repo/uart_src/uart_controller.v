`timescale 1ns / 1ps

// MMIO UART: 0x8000_0000 data, 0x8000_0004 status {rx_ready, tx_busy}
// Default 50 MHz for tb_uart. Board system_top overrides CLK_FREQ=100_000_000.
// HW_ECHO: 收完一字节立刻从硬件发出去（不经过 CPU），用来确认 RX 脚是否通。
module uart_controller #(
    parameter HALF_DUPLEX = 0,
    parameter HW_ECHO     = 0,
    parameter CLK_FREQ    = 50_000_000,
    parameter BAUD        = 115200,
    parameter BAUD_CNT_MAX = CLK_FREQ / BAUD
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we_i,
    input  wire        re_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] wdata_i,
    output reg  [31:0] rdata_o,
    input  wire        rx,
    output wire        tx
);

    wire       tx_busy;
    wire [7:0] rx_data;
    wire       rx_done;
    reg        rx_ready;
    reg        hw_tx_en;
    reg  [7:0] hw_tx_data;

    wire sel_uart = (addr_i[31:28] == 4'h8);
    wire sel_data = sel_uart && (addr_i[3:2] == 2'b00);
    wire sel_stat = sel_uart && (addr_i[3:2] == 2'b01);

    wire cpu_tx_en = we_i && sel_data;
    wire rd_data   = re_i && sel_data;
    wire tx_en     = cpu_tx_en || hw_tx_en;
    wire [7:0] tx_data = hw_tx_en ? hw_tx_data : wdata_i[7:0];
    wire rx_in     = (HALF_DUPLEX && tx_busy) ? 1'b1 : rx;

    uart_tx #(.BAUD_CNT_MAX(BAUD_CNT_MAX)) u_tx (
        .clk    (clk),
        .rst_n  (rst_n),
        .tx_en  (tx_en),
        .data_in(tx_data),
        .tx     (tx),
        .tx_busy(tx_busy)
    );

    uart_rx #(
        .BAUD_CNT_MAX (BAUD_CNT_MAX),
        .BAUD_CNT_HALF(BAUD_CNT_MAX / 2)
    ) u_rx (
        .clk     (clk),
        .rst_n   (rst_n),
        .rx      (rx_in),
        .data_out(rx_data),
        .rx_done (rx_done)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hw_tx_en   <= 1'b0;
            hw_tx_data <= 8'd0;
        end else begin
            hw_tx_en <= 1'b0;
            if (HW_ECHO && rx_done && !tx_busy) begin
                hw_tx_en   <= 1'b1;
                hw_tx_data <= rx_data;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_ready <= 1'b0;
        else if (rd_data || cpu_tx_en)
            rx_ready <= 1'b0;
        else if (rx_done)
            rx_ready <= 1'b1;
    end

    always @(*) begin
        if (sel_data)
            rdata_o = {24'd0, rx_data};
        else if (sel_stat)
            rdata_o = {30'd0, rx_ready, tx_busy};
        else
            rdata_o = 32'd0;
    end

endmodule
