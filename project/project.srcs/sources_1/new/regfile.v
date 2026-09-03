`timescale 1ns / 1ps

// 32 x 32 通用寄存器堆。x0 恒为 0。
// 同步写、组合读；同一拍 WB 写 / ID 读同一寄存器时，读口直接拿到写数据（写优先）。
module regfile (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  wa,
    input  wire [31:0] wd,
    input  wire [4:0]  ra1,
    input  wire [4:0]  ra2,
    output wire [31:0] rd1,
    output wire [31:0] rd2,
    input  wire [4:0]  ra3,
    output wire [31:0] rd3
);
    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'd0;
    end

    always @(posedge clk) begin
        if (we && (wa != 5'd0))
            regs[wa] <= wd;
    end

    assign rd1 = (ra1 == 5'd0) ? 32'd0 :
                 (we && (wa == ra1)) ? wd : regs[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'd0 :
                 (we && (wa == ra2)) ? wd : regs[ra2];
    assign rd3 = (ra3 == 5'd0) ? 32'd0 : regs[ra3];
endmodule
