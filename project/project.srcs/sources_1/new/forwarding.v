`timescale 1ns / 1ps

// EX 级数据旁路：优先用 EX/MEM（相邻指令），其次 MEM/WB（隔一条）。
// 2'b00 用寄存器堆读值；2'b10 用 MEM 级 ALU 结果；2'b01 用 WB 级写回值。
module forwarding (
    input  wire        ex_mem_regwrite,
    input  wire        mem_wb_regwrite,
    input  wire [4:0]  ex_mem_rd,
    input  wire [4:0]  mem_wb_rd,
    input  wire [4:0]  id_ex_rs1,
    input  wire [4:0]  id_ex_rs2,
    output reg  [1:0]  forward_a,
    output reg  [1:0]  forward_b
);
    always @(*) begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (ex_mem_regwrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1))
            forward_a = 2'b10;
        else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1))
            forward_a = 2'b01;

        if (ex_mem_regwrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2))
            forward_b = 2'b10;
        else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2))
            forward_b = 2'b01;
    end
endmodule
