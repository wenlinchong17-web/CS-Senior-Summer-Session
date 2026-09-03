`timescale 1ns / 1ps

// load-use 数据冒险：前一条是 LW 且本条要用它的 rd，则停顿 1 拍。
// 分支/跳转在 EX 判定后，冲刷 IF/ID 与即将进入 EX 的错误路径指令。
module hazard (
    input  wire        id_ex_memread,
    input  wire [4:0]  id_ex_rd,
    input  wire        if_id_use_rs1,
    input  wire        if_id_use_rs2,
    input  wire [4:0]  if_id_rs1,
    input  wire [4:0]  if_id_rs2,
    input  wire        pc_redirect,
    output wire        stall,
    output wire        if_id_flush,
    output wire        id_ex_flush
);
    wire load_use = id_ex_memread && (id_ex_rd != 5'd0) &&
                    ((if_id_use_rs1 && (id_ex_rd == if_id_rs1)) ||
                     (if_id_use_rs2 && (id_ex_rd == if_id_rs2)));

    assign stall       = load_use && !pc_redirect;
    assign if_id_flush = pc_redirect;
    assign id_ex_flush = pc_redirect;
endmodule
