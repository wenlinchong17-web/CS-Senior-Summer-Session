`include "rv32_defines.vh"

// EX 级算术逻辑单元。操作由微指令 ALUOp 字段指定。
// ov：有符号溢出。仅 ADD/SUB 有意义；是否因此陷入由微指令 ChkOv 决定。
module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] y,
    output reg         ov
);
    always @(*) begin
        y  = 32'd0;
        ov = 1'b0;
        case (alu_op)
            `ALU_ADD: begin
                y  = a + b;
                ov = (a[31] == b[31]) && (y[31] != a[31]);
            end
            `ALU_SUB: begin
                y  = a - b;
                ov = (a[31] != b[31]) && (y[31] != a[31]);
            end
            `ALU_AND: y = a & b;
            `ALU_OR:  y = a | b;
            `ALU_XOR: y = a ^ b;
            `ALU_SLT: y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `ALU_LUI: y = b;          // LUI：结果就是已经左移 12 位的 U 立即数
            default:  y = 32'd0;
        endcase
    end
endmodule
