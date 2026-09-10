# CPU 自测程序（与 imem.V UART_DEMO=0 机器码一致，勿用 gnu as 直接汇编本文件里的伪标号）
# dmem[地址4]=0x7FFFFFFF，dmem[地址12]=1
# 溢出处理：PC=0x80 处 addi x31,x0,1，然后 jal x0,0 停机

# PC     指令
# 00     addi  x1,  x0, 10
# 04     addi  x2,  x0, 20
# 08     add   x3,  x1, x2          # 旁路
# 0C     sub   x4,  x3, x1          # 旁路
# 10     and   x5,  x1, x2
# 14     or    x6,  x1, x2
# 18     xor   x7,  x1, x2
# 1C     slt   x8,  x1, x2
# 20     andi  x21, x1, 15
# 24     ori   x22, x1, 1
# 28     sw    x3,  0(x0)
# 2C     lw    x9,  0(x0)
# 30     add   x10, x9, x1          # load-use 停顿
# 34     beq   x1,  x2, +8          # 不跳转
# 38     addi  x11, x0, 1
# 3C     bne   x1,  x2, +8          # 跳转，冲刷下一条
# 40     addi  x12, x0, 99          # 应被冲刷
# 44     addi  x12, x0, 2
# 48     jal   x13, +8              # x13=0x4C
# 4C     addi  x14, x0, 99          # 应被冲刷
# 50     lui   x15, 1               # x15=0x1000
# 54     auipc x16, 0               # x16=0x54
# 58     addi  x17, x0, 0x68
# 5C     jalr  x18, 0(x17)          # 跳到 0x68，x18=0x60
# 60     addi  x19, x0, 99          # 应被冲刷
# 64     addi  x20, x0, 99          # 应被冲刷
# 68     addi  x19, x0, 7           # jalr 目标
# 6C     addi  x20, x0, 8
# 70     lw    x23, 4(x0)           # 0x7FFFFFFF
# 74     lw    x24, 12(x0)          # 1
# 78     add   x29, x23, x0         # 不溢出
# 7C     add   x25, x23, x24        # 正溢出，EPC=0x7C
# 80     addi  x31, x0, 1           # 溢出处理
# 84     jal   x0, 0                # 停机
