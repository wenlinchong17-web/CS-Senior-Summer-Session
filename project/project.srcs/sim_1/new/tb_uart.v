`timescale 1ns / 1ps

// 测 UART 外设（不跑 CPU）。时钟 50 MHz，与 BAUD_CNT_MAX=434 一致。
// 一帧约 87 us。不要用 run all：时钟永不停止，wait 若没等到会把 XSim 卡死。
// 正确做法：Launch 后执行  run 400us
// 或把 Simulation Settings 里 xsim.simulate.runtime 改成 400us。
module tb_uart;
    localparam [7:0] BYTE_A = 8'h41;
    localparam [7:0] BYTE_U = 8'h55;
    localparam integer BIT_CLKS = 434;
    localparam integer FRAME_CLKS = 12 * BIT_CLKS; // 一帧 10 bit，留余量

    reg clk   = 1'b0;
    reg rst_n = 1'b0;
    always #10 clk = ~clk;

    integer fail;
    integer pass;
    integer tmo;

    // -------------------------------------------------------------------------
    // 1) 物理层：TX 接到 RX
    // -------------------------------------------------------------------------
    reg        tx_en;
    reg  [7:0] data_in;
    wire       tx;
    wire       tx_busy;
    wire [7:0] data_out;
    wire       rx_done;

    uart_tx u_tx (
        .clk    (clk),
        .rst_n  (rst_n),
        .tx_en  (tx_en),
        .data_in(data_in),
        .tx     (tx),
        .tx_busy(tx_busy)
    );

    uart_rx u_rx (
        .clk     (clk),
        .rst_n   (rst_n),
        .rx      (tx),
        .data_out(data_out),
        .rx_done (rx_done)
    );

    integer    rx_count;
    reg  [7:0] cap_rx;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_count <= 0;
            cap_rx   <= 8'd0;
        end else if (rx_done) begin
            rx_count <= rx_count + 1;
            cap_rx   <= data_out;
        end
    end

    // -------------------------------------------------------------------------
    // 2) MMIO 控制器，TX 回环到 RX
    // -------------------------------------------------------------------------
    reg         we_i;
    reg  [31:0] addr_i;
    reg  [31:0] wdata_i;
    wire [31:0] rdata_o;
    wire        c_tx;

    uart_controller u_ctrl (
        .clk    (clk),
        .rst_n  (rst_n),
        .we_i   (we_i),
        .addr_i (addr_i),
        .wdata_i(wdata_i),
        .rdata_o(rdata_o),
        .rx     (c_tx),
        .tx     (c_tx)
    );

    wire       c_rx_done = u_ctrl.u_rx.rx_done;
    wire [7:0] c_rx_data = u_ctrl.u_rx.data_out;
    wire       c_tx_busy = u_ctrl.u_tx.tx_busy;

    integer    mmio_count;
    reg  [7:0] cap_mmio;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mmio_count <= 0;
            cap_mmio   <= 8'd0;
        end else if (c_rx_done) begin
            mmio_count <= mmio_count + 1;
            cap_mmio   <= c_rx_data;
        end
    end

    // 等 tx 空闲后再隔 2 拍才拉 tx_en，避免和 busy 下降沿撞在同一拍把脉冲吃掉
    task send_byte;
        input [7:0] b;
        begin
            tmo = 0;
            while (tx_busy === 1'b1 && tmo < FRAME_CLKS) begin
                @(posedge clk);
                tmo = tmo + 1;
            end
            if (tx_busy === 1'b1) begin
                $display("TIMEOUT waiting tx idle before 0x%02h", b);
                fail = fail + 1;
            end
            repeat (2) @(posedge clk);
            $display("[%0t] loopback send 0x%02h", $time, b);
            data_in = b;
            tx_en   = 1'b1;
            @(posedge clk);
            tx_en   = 1'b0;
            @(posedge clk);
            if (tx_busy !== 1'b1) begin
                $display("FAIL: tx_busy did not rise after sending 0x%02h", b);
                fail = fail + 1;
            end
        end
    endtask

    task wait_rx_count;
        input integer n;
        begin
            tmo = 0;
            while (rx_count < n && tmo < FRAME_CLKS) begin
                @(posedge clk);
                tmo = tmo + 1;
            end
            if (rx_count < n) begin
                $display("TIMEOUT waiting rx_count==%0d (now %0d)", n, rx_count);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        fail    = 0;
        pass    = 0;
        tx_en   = 1'b0;
        data_in = 8'd0;
        we_i    = 1'b0;
        addr_i  = 32'd0;
        wdata_i = 32'd0;

        repeat (8) @(posedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        send_byte(BYTE_A);
        wait_rx_count(1);
        if (cap_rx !== BYTE_A) begin
            $display("FAIL: loopback got 0x%02h expect 0x%02h", cap_rx, BYTE_A);
            fail = fail + 1;
        end else
            $display("PASS: loopback 0x%02h", cap_rx);

        send_byte(BYTE_U);
        wait_rx_count(2);
        if (cap_rx !== BYTE_U) begin
            $display("FAIL: loopback got 0x%02h expect 0x%02h", cap_rx, BYTE_U);
            fail = fail + 1;
        end else
            $display("PASS: loopback 0x%02h", cap_rx);

        tmo = 0;
        while (tx_busy === 1'b1 && tmo < FRAME_CLKS) begin
            @(posedge clk);
            tmo = tmo + 1;
        end
        repeat (2) @(posedge clk);

        addr_i = 32'h8000_0004;
        #1;
        if (rdata_o !== 32'd0) begin
            $display("FAIL: idle status rdata=%h expect 0", rdata_o);
            fail = fail + 1;
        end

        $display("[%0t] MMIO sw 0x41 -> 0x80000000", $time);
        addr_i  = 32'h8000_0000;
        wdata_i = {24'd0, BYTE_A};
        we_i    = 1'b1;
        @(posedge clk);
        we_i    = 1'b0;
        @(posedge clk);

        addr_i = 32'h8000_0004;
        #1;
        if (rdata_o[0] !== 1'b1) begin
            $display("FAIL: status bit0 (tx_busy) not 1 after write");
            fail = fail + 1;
        end

        tmo = 0;
        while (mmio_count < 1 && tmo < FRAME_CLKS) begin
            @(posedge clk);
            tmo = tmo + 1;
        end
        if (mmio_count < 1) begin
            $display("TIMEOUT waiting MMIO RX");
            fail = fail + 1;
        end else if (cap_mmio !== BYTE_A) begin
            $display("FAIL: MMIO loopback got 0x%02h expect 0x%02h", cap_mmio, BYTE_A);
            fail = fail + 1;
        end else
            $display("PASS: MMIO loopback 0x%02h", cap_mmio);

        tmo = 0;
        while (c_tx_busy === 1'b1 && tmo < FRAME_CLKS) begin
            @(posedge clk);
            tmo = tmo + 1;
        end
        addr_i = 32'h8000_0000;
        #1;
        if (rdata_o[7:0] !== BYTE_A) begin
            $display("FAIL: read DATA got 0x%02h expect 0x%02h", rdata_o[7:0], BYTE_A);
            fail = fail + 1;
        end else
            $display("PASS: read DATA 0x%02h", rdata_o[7:0]);

        pass = (fail == 0);
        if (pass)
            $display("UART PASS");
        else
            $display("UART FAIL  mismatches=%0d", fail);

        #20;
        $finish;
    end
endmodule
