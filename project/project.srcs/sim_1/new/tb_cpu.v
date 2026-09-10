`timescale 1ns / 1ps

// 自校验测试平台。波形请看本文件里的 x1..x31、dbg_pc、dbg_epc，不要看 dbg_reg_addr。
// fail 全程为 0 且最后 Tcl 打印 TEST PASS 才算通过。
module tb_cpu;
    reg         clk;
    reg         rst;
    wire [31:0] dbg_pc;
    wire        dbg_stall;
    wire        dbg_flush;
    wire [31:0] dbg_reg_data;
    reg  [4:0]  dbg_reg_addr = 5'd1;
    wire [4:0]  dbg_uaddr;
    wire        dbg_overflow;
    wire [31:0] dbg_epc;
    wire [31:0] dbg_perf_cycles;
    wire [31:0] dbg_perf_inst;
    wire [31:0] dbg_perf_stall;
    wire [31:0] dbg_perf_flush;

    wire        mem_we;
    wire        mem_re;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;

    cpu_top dut (
        .clk            (clk),
        .rst            (rst),
        .mem_we_o       (mem_we),
        .mem_re_o       (mem_re),
        .mem_addr_o     (mem_addr),
        .mem_wdata_o    (mem_wdata),
        .mem_rdata_i    (mem_rdata),
        .dbg_pc         (dbg_pc),
        .dbg_stall      (dbg_stall),
        .dbg_flush      (dbg_flush),
        .dbg_reg_data   (dbg_reg_data),
        .dbg_reg_addr   (dbg_reg_addr),
        .dbg_uaddr      (dbg_uaddr),
        .dbg_overflow   (dbg_overflow),
        .dbg_epc        (dbg_epc),
        .dbg_perf_cycles(dbg_perf_cycles),
        .dbg_perf_inst  (dbg_perf_inst),
        .dbg_perf_stall (dbg_perf_stall),
        .dbg_perf_flush (dbg_perf_flush)
    );

    // dmem 已从 cpu_top 拆到总线上，testbench 必须把它接回去，lw/sw 才不是 X
    dmem u_dmem (
        .clk  (clk),
        .we   (mem_we),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .rdata(mem_rdata)
    );

    // 波形里请加这些：仿真过程中会陆续变成期望值
    wire [31:0] x1  = dut.u_regfile.regs[1];
    wire [31:0] x2  = dut.u_regfile.regs[2];
    wire [31:0] x3  = dut.u_regfile.regs[3];
    wire [31:0] x4  = dut.u_regfile.regs[4];
    wire [31:0] x5  = dut.u_regfile.regs[5];
    wire [31:0] x6  = dut.u_regfile.regs[6];
    wire [31:0] x7  = dut.u_regfile.regs[7];
    wire [31:0] x8  = dut.u_regfile.regs[8];
    wire [31:0] x9  = dut.u_regfile.regs[9];
    wire [31:0] x10 = dut.u_regfile.regs[10];
    wire [31:0] x11 = dut.u_regfile.regs[11];
    wire [31:0] x12 = dut.u_regfile.regs[12];
    wire [31:0] x13 = dut.u_regfile.regs[13];
    wire [31:0] x14 = dut.u_regfile.regs[14];
    wire [31:0] x15 = dut.u_regfile.regs[15];
    wire [31:0] x16 = dut.u_regfile.regs[16];
    wire [31:0] x17 = dut.u_regfile.regs[17];
    wire [31:0] x18 = dut.u_regfile.regs[18];
    wire [31:0] x19 = dut.u_regfile.regs[19];
    wire [31:0] x20 = dut.u_regfile.regs[20];
    wire [31:0] x21 = dut.u_regfile.regs[21];
    wire [31:0] x22 = dut.u_regfile.regs[22];
    wire [31:0] x23 = dut.u_regfile.regs[23];
    wire [31:0] x24 = dut.u_regfile.regs[24];
    wire [31:0] x25 = dut.u_regfile.regs[25];
    wire [31:0] x29 = dut.u_regfile.regs[29];
    wire [31:0] x31 = dut.u_regfile.regs[31];

    integer fail;
    integer pass;   // 1 = 全部比对成功
    integer done;   // 1 = 已经跑完比对
    integer cpi_milli;
    integer ipc_milli;
    integer mips_milli;

    // 波形请加这个：1847 表示 CPI=1.847（XSim 的 real/%f 经常显示成 0）
    wire [31:0] cpi_x1000 =
        (dbg_perf_inst == 32'd0) ? 32'd0 :
        (dbg_perf_cycles * 32'd1000) / dbg_perf_inst;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // 让 dbg_reg_addr / dbg_reg_data 在波形上动起来（只是观察口，不影响 CPU）
    always @(posedge clk) begin
        if (rst)
            dbg_reg_addr <= 5'd1;
        else if (dbg_reg_addr >= 5'd31)
            dbg_reg_addr <= 5'd1;
        else
            dbg_reg_addr <= dbg_reg_addr + 5'd1;
    end

    initial begin
        fail = 0;
        pass = 0;
        done = 0;
        rst  = 1'b1;
        $display("[%0t] reset=1  (dbg_pc stays 0 here, this is normal)", $time);
        repeat (4) @(posedge clk);
        rst = 1'b0;
        $display("[%0t] reset=0  dbg_pc should start +4 each cycle", $time);

        repeat (150) @(posedge clk);

        $display("==== register dump ====");
        $display("pc  = %h  stall=%b flush=%b uaddr=%0d ov=%b epc=%h",
                 dbg_pc, dbg_stall, dbg_flush, dbg_uaddr, dbg_overflow, dbg_epc);
        $display("x1  = %0d (expect 10)",  x1);
        $display("x2  = %0d (expect 20)",  x2);
        $display("x3  = %0d (expect 30)",  x3);
        $display("x4  = %0d (expect 20)",  x4);
        $display("x5  = %0d (expect 0)",   x5);
        $display("x6  = %0d (expect 30)",  x6);
        $display("x7  = %0d (expect 30)",  x7);
        $display("x8  = %0d (expect 1)",   x8);
        $display("x9  = %0d (expect 30)",  x9);
        $display("x10 = %0d (expect 40)",  x10);
        $display("x11 = %0d (expect 1)",   x11);
        $display("x12 = %0d (expect 2)",   x12);
        $display("x13 = %h (expect 0000004c)", x13);
        $display("x14 = %0d (expect 0)",   x14);
        $display("x15 = %h (expect 00001000)", x15);
        $display("x16 = %h (expect 00000054)", x16);
        $display("x17 = %h (expect 00000068)", x17);
        $display("x18 = %h (expect 00000060)", x18);
        $display("x19 = %0d (expect 7)",   x19);
        $display("x20 = %0d (expect 8)",   x20);
        $display("x21 = %0d (expect 10)",  x21);
        $display("x22 = %0d (expect 11)",  x22);
        $display("x23 = %h (expect 7fffffff)", x23);
        $display("x24 = %0d (expect 1)",   x24);
        $display("x25 = %h (expect 00000000, overflow must not write)", x25);
        $display("x29 = %h (expect 7fffffff, no overflow)", x29);
        $display("x31 = %0d (expect 1, handler)", x31);

        if (x1  !== 32'd10)     fail = fail + 1;
        if (x2  !== 32'd20)     fail = fail + 1;
        if (x3  !== 32'd30)     fail = fail + 1;
        if (x4  !== 32'd20)     fail = fail + 1;
        if (x5  !== 32'd0)      fail = fail + 1;
        if (x6  !== 32'd30)     fail = fail + 1;
        if (x7  !== 32'd30)     fail = fail + 1;
        if (x8  !== 32'd1)      fail = fail + 1;
        if (x9  !== 32'd30)     fail = fail + 1;
        if (x10 !== 32'd40)     fail = fail + 1;
        if (x11 !== 32'd1)      fail = fail + 1;
        if (x12 !== 32'd2)      fail = fail + 1;
        if (x13 !== 32'h0000004c) fail = fail + 1;
        if (x14 !== 32'd0)      fail = fail + 1;
        if (x15 !== 32'h00001000) fail = fail + 1;
        if (x16 !== 32'h00000054) fail = fail + 1;
        if (x17 !== 32'h00000068) fail = fail + 1;
        if (x18 !== 32'h00000060) fail = fail + 1;
        if (x19 !== 32'd7)      fail = fail + 1;
        if (x20 !== 32'd8)      fail = fail + 1;
        if (x21 !== 32'd10)     fail = fail + 1;
        if (x22 !== 32'd11)     fail = fail + 1;
        if (x23 !== 32'h7FFFFFFF) fail = fail + 1;
        if (x24 !== 32'd1)      fail = fail + 1;
        if (x25 !== 32'd0)      fail = fail + 1;
        if (x29 !== 32'h7FFFFFFF) fail = fail + 1;
        if (x31 !== 32'd1)      fail = fail + 1;
        if (dbg_overflow !== 1'b1) fail = fail + 1;
        if (dbg_epc !== 32'h0000007C) fail = fail + 1;
        if (dbg_pc < 32'h00000080 || dbg_pc > 32'h00000088) fail = fail + 1;

        done = 1;
        pass = (fail == 0);
        if (pass)
            $display("TEST PASS");
        else
            $display("TEST FAIL  mismatches=%0d", fail);

        // 性能：测量窗口 = 复位释放 → 停机 jal 提交（不含死循环）
        // 不用 $display %f：XSim 打印 real 经常全是 0。
        if (dbg_perf_inst == 32'd0) begin
            $display("==== performance ====");
            $display("no committed instruction, skip CPI");
        end else begin
            cpi_milli  = (dbg_perf_cycles * 1000) / dbg_perf_inst;
            ipc_milli  = (dbg_perf_inst   * 1000) / dbg_perf_cycles;
            mips_milli = (dbg_perf_inst   * 100000) / dbg_perf_cycles; // IPC*100 MHz
            $display("==== performance ====");
            $display("C (cycles)     = %0d", dbg_perf_cycles);
            $display("N (committed)  = %0d", dbg_perf_inst);
            $display("stall cycles   = %0d", dbg_perf_stall);
            $display("redirects      = %0d  (taken branch/jump/overflow)", dbg_perf_flush);
            $display("CPI            = %0d.%03d  (ideal 5-stage = 1.000)",
                     cpi_milli/1000, cpi_milli%1000);
            $display("IPC            = %0d.%03d",
                     ipc_milli/1000, ipc_milli%1000);
            $display("MIPS @ 100 MHz = %0d.%03d",
                     mips_milli/1000, mips_milli%1000);
            $display("CPU time       = %0d ns  (C * 10 ns)", dbg_perf_cycles * 10);
            $display("CPI extra      = %0d.%03d  (= CPI-1)",
                     (cpi_milli-1000)/1000, (cpi_milli-1000)%1000);
        end

        // 停住而不是退出，方便在 GUI 里看波形末尾
        #20;
        $stop;
    end
endmodule
