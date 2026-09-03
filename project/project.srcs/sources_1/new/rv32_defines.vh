// -----------------------------------------------------------------------------
// RV32I 子集 + 微程序控制字格式
// 微指令 21 bit，水平型、直接控制，每条机器指令对应 1 条微指令。
// -----------------------------------------------------------------------------
`ifndef RV32_DEFINES_VH
`define RV32_DEFINES_VH

`timescale 1ns / 1ps

// opcode（RISC-V 标准）
`define OP_LUI    7'b0110111
`define OP_AUIPC  7'b0010111
`define OP_JAL    7'b1101111
`define OP_JALR   7'b1100111
`define OP_BRANCH 7'b1100011
`define OP_LOAD   7'b0000011
`define OP_STORE  7'b0100011
`define OP_OPIMM  7'b0010011
`define OP_OP     7'b0110011

// 微地址（控制存储器行号）
`define U_INVALID 5'd0 //全0微指令
`define U_ADD     5'd1
`define U_SUB     5'd2
`define U_AND     5'd3
`define U_OR      5'd4
`define U_XOR     5'd5
`define U_SLT     5'd6
`define U_ADDI    5'd7
`define U_ANDI    5'd8
`define U_ORI     5'd9
`define U_LW      5'd10
`define U_SW      5'd11
`define U_LUI     5'd12
`define U_AUIPC   5'd13
`define U_BEQ     5'd14
`define U_BNE     5'd15
`define U_JAL     5'd16
`define U_JALR    5'd17

// 微指令字段（ctrl[20:0]）
// [20]    ChkOv      EX 是否检查有符号溢出（仅 add/sub/addi）
// [19]    UseRs1     ID 是否读 rs1（冒险检测用）
// [18]    UseRs2     ID 是否读 rs2
// [17]    RegWrite   WB 写寄存器
// [16:15] MemToReg   00=ALU  01=MEM  10=PC+4
// [14]    MemRead    MEM 读数据存储器
// [13]    MemWrite   MEM 写数据存储器
// [12]    Branch     EX 条件分支
// [11]    Jump       EX 无条件跳转
// [10]    JumpSrc    0=PC+imm (JAL/B)  1=rs1+imm (JALR)
// [9]     ALUSrcA    0=rs1  1=PC
// [8]     ALUSrcB    0=rs2  1=imm
// [7:4]   ALUOp
// [3:1]   ImmSel     000=I 001=S 010=B 011=U 100=J
// [0]     Valid
`define CTRL_W        21
`define C_CHKOV       20
`define C_USERS1      19
`define C_USERS2      18
`define C_REGWRITE    17
`define C_MEMTOREG    16:15
`define C_MEMREAD     14
`define C_MEMWRITE    13
`define C_BRANCH      12
`define C_JUMP        11
`define C_JUMPSRC     10
`define C_ALUSRCA     9
`define C_ALUSRCB     8
`define C_ALUOP       7:4
`define C_IMMSEL      3:1
`define C_VALID       0

`define ALU_ADD  4'b0000
`define ALU_SUB  4'b0001
`define ALU_AND  4'b0010
`define ALU_OR   4'b0011
`define ALU_XOR  4'b0100
`define ALU_SLT  4'b0101
`define ALU_LUI  4'b0110

`define IMM_I  3'b000
`define IMM_S  3'b001
`define IMM_B  3'b010
`define IMM_U  3'b011
`define IMM_J  3'b100

`define MTR_ALU  2'b00
`define MTR_MEM  2'b01
`define MTR_PC4  2'b10

`define NOP_INST 32'h00000013   // addi x0, x0, 0

// 有符号溢出异常入口（精确异常：不写回、冲刷年轻指令、PC 改到此处）
`define OV_HANDLER 32'h00000080
// 停机指令 jal x0,0 位于 0x84，其 PC+4 用于性能计数窗口结束
`define HALT_PC4   32'h00000088

`endif
