`include "rv32_defines.vh"

// 指令存储器（ROM）。字寻址：pc[9:2] -> 256 条指令。
// UART_DEMO=0：CPU 自测（给 tb_cpu 用）
// UART_DEMO=1：上板串口回显。复位后先发 0x55，再由 CPU 轮询回显
// 汇编对照：software/cpu_test.S、software/uart_echo.S
module imem (
    input  wire [31:0] addr,
    output wire [31:0] inst
);
    localparam UART_DEMO = 1;

    (* ram_style = "block" *) reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = `NOP_INST;

        if (UART_DEMO) begin
            mem[ 0] = 32'h800000B7; // lui  x1, 0x80000
            mem[ 1] = 32'h05500113; // addi x2, x0, 0x55      上电探针 'U'
            mem[ 2] = 32'h0020A023; // sw   x2, 0(x1)
            mem[ 3] = 32'h0041A183; // lw   x3, 4(x1)          wait_rx
            mem[ 4] = 32'h0021F193; // andi x3, x3, 2
            mem[ 5] = 32'hFE018CE3; // beq  x3, x0, -8
            mem[ 6] = 32'h0000A103; // lw   x2, 0(x1)
            mem[ 7] = 32'h0041A183; // lw   x3, 4(x1)          wait_tx
            mem[ 8] = 32'h0011F193; // andi x3, x3, 1
            mem[ 9] = 32'hFE019CE3; // bne  x3, x0, -8
            mem[10] = 32'h0020A023; // sw   x2, 0(x1)
            mem[11] = 32'hFE0000E3; // beq  x0, x0, -32        回到 wait_rx
        end else begin
            mem[ 0] = 32'h00A00093; // addi x1,  x0, 10
            mem[ 1] = 32'h01400113; // addi x2,  x0, 20
            mem[ 2] = 32'h002081B3; // add  x3,  x1, x2        旁路
            mem[ 3] = 32'h40118233; // sub  x4,  x3, x1        旁路
            mem[ 4] = 32'h0020F2B3; // and  x5,  x1, x2
            mem[ 5] = 32'h0020E333; // or   x6,  x1, x2
            mem[ 6] = 32'h0020C3B3; // xor  x7,  x1, x2
            mem[ 7] = 32'h0020A433; // slt  x8,  x1, x2
            mem[ 8] = 32'h00F0FA93; // andi x21, x1, 15
            mem[ 9] = 32'h0010EB13; // ori  x22, x1, 1
            mem[10] = 32'h00302023; // sw   x3,  0(x0)
            mem[11] = 32'h00002483; // lw   x9,  0(x0)
            mem[12] = 32'h00148533; // add  x10, x9, x1        load-use 停顿
            mem[13] = 32'h00208463; // beq  x1,  x2, +8        不跳转
            mem[14] = 32'h00100593; // addi x11, x0, 1
            mem[15] = 32'h00209463; // bne  x1,  x2, +8        跳转，冲刷下一条
            mem[16] = 32'h06300613; // addi x12, x0, 99        应被冲刷
            mem[17] = 32'h00200613; // addi x12, x0, 2
            mem[18] = 32'h008006EF; // jal  x13, +8            x13=0x4C
            mem[19] = 32'h06300713; // addi x14, x0, 99        应被冲刷
            mem[20] = 32'h000017B7; // lui  x15, 1             x15=0x1000
            mem[21] = 32'h00000817; // auipc x16, 0            x16=0x54
            mem[22] = 32'h06800893; // addi x17, x0, 0x68
            mem[23] = 32'h00088967; // jalr x18, 0(x17)        跳到 0x68，x18=0x60
            mem[24] = 32'h06300993; // addi x19, x0, 99        应被冲刷
            mem[25] = 32'h06300A13; // addi x20, x0, 99        应被冲刷
            mem[26] = 32'h00700993; // addi x19, x0, 7         jalr 目标
            mem[27] = 32'h00800A13; // addi x20, x0, 8
            mem[28] = 32'h00402B83; // lw   x23, 4(x0)         0x7FFFFFFF
            mem[29] = 32'h00C02C03; // lw   x24, 12(x0)        1
            mem[30] = 32'h000B8EB3; // add  x29, x23, x0       不溢出
            mem[31] = 32'h018B8CB3; // add  x25, x23, x24      正溢出，PC=0x7C
            mem[32] = 32'h00100F93; // addi x31, x0, 1
            mem[33] = 32'h0000006F; // jal  x0, 0              停机
        end
    end

    assign inst = mem[addr[9:2]];
endmodule
