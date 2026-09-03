`timescale 1ns / 1ps

// 数据存储器。与 imem 分离，消除取指/访存结构相关。
module dmem (
    input  wire        clk,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);
    (* ram_style = "block" *) reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'd0;
        mem[1] = 32'h7FFFFFFF; // 地址 4：有符号最大正数
        mem[3] = 32'd1;        // 地址 12
    end

    always @(posedge clk) begin
        if (we)
            mem[addr[9:2]] <= wdata;
    end

    assign rdata = mem[addr[9:2]];
endmodule
