`include "rv32_defines.vh"

// 微程序控制器：
//   1) 微地址形成：opcode/funct3/funct7 映射到 5 位微地址
//   2) 控制存储器：32 x 21bit ROM，读出一条水平型微指令
// IF 取指时序不走微程序；冒险互锁也不走微程序。
module micro_ctrl (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output wire [4:0] uaddr,
    output wire [`CTRL_W-1:0] ctrl
);
    reg [4:0] uaddr_r;
    assign uaddr = uaddr_r;

    // -------- 微地址形成电路 --------
    always @(*) begin
        uaddr_r = `U_INVALID;
        case (opcode)
            `OP_OP: begin
                case ({funct7[5], funct3})
                    4'b0000: uaddr_r = `U_ADD;
                    4'b1000: uaddr_r = `U_SUB;
                    4'b0111: uaddr_r = `U_AND;
                    4'b0110: uaddr_r = `U_OR;
                    4'b0100: uaddr_r = `U_XOR;
                    4'b0010: uaddr_r = `U_SLT;
                    default: uaddr_r = `U_INVALID;
                endcase
            end
            `OP_OPIMM: begin
                case (funct3)
                    3'b000:  uaddr_r = `U_ADDI;
                    3'b111:  uaddr_r = `U_ANDI;
                    3'b110:  uaddr_r = `U_ORI;
                    default: uaddr_r = `U_INVALID;
                endcase
            end
            `OP_LOAD:   if (funct3 == 3'b010) uaddr_r = `U_LW;
            `OP_STORE:  if (funct3 == 3'b010) uaddr_r = `U_SW;
            `OP_LUI:    uaddr_r = `U_LUI;
            `OP_AUIPC:  uaddr_r = `U_AUIPC;
            `OP_BRANCH: begin
                case (funct3)
                    3'b000:  uaddr_r = `U_BEQ;
                    3'b001:  uaddr_r = `U_BNE;
                    default: uaddr_r = `U_INVALID;
                endcase
            end
            `OP_JAL:    uaddr_r = `U_JAL;
            `OP_JALR:   if (funct3 == 3'b000) uaddr_r = `U_JALR;
            default:    uaddr_r = `U_INVALID;
        endcase
    end

    // -------- 控制存储器（微程序 ROM）--------
    // 字段：ChkOv UseRs1 UseRs2 RegWrite MemToReg MemRead MemWrite Branch Jump JumpSrc ALUSrcA ALUSrcB ALUOp ImmSel Valid
    reg [`CTRL_W-1:0] cstore [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            cstore[i] = {`CTRL_W{1'b0}};

        //                 OV U1 U2 RW MTR MR MW Br J JS A  B  ALU    Imm V
        cstore[`U_ADD]   = 21'b1_1_1_1_00_0_0_0_0_0_0_0_0000_000_1;
        cstore[`U_SUB]   = 21'b1_1_1_1_00_0_0_0_0_0_0_0_0001_000_1;
        cstore[`U_AND]   = 21'b0_1_1_1_00_0_0_0_0_0_0_0_0010_000_1;
        cstore[`U_OR]    = 21'b0_1_1_1_00_0_0_0_0_0_0_0_0011_000_1;
        cstore[`U_XOR]   = 21'b0_1_1_1_00_0_0_0_0_0_0_0_0100_000_1;
        cstore[`U_SLT]   = 21'b0_1_1_1_00_0_0_0_0_0_0_0_0101_000_1;
        cstore[`U_ADDI]  = 21'b1_1_0_1_00_0_0_0_0_0_0_1_0000_000_1;
        cstore[`U_ANDI]  = 21'b0_1_0_1_00_0_0_0_0_0_0_1_0010_000_1;
        cstore[`U_ORI]   = 21'b0_1_0_1_00_0_0_0_0_0_0_1_0011_000_1;
        cstore[`U_LW]    = 21'b0_1_0_1_01_1_0_0_0_0_0_1_0000_000_1;
        cstore[`U_SW]    = 21'b0_1_1_0_00_0_1_0_0_0_0_1_0000_001_1;
        cstore[`U_LUI]   = 21'b0_0_0_1_00_0_0_0_0_0_0_1_0110_011_1;
        cstore[`U_AUIPC] = 21'b0_0_0_1_00_0_0_0_0_0_1_1_0000_011_1;
        cstore[`U_BEQ]   = 21'b0_1_1_0_00_0_0_1_0_0_0_0_0000_010_1;
        cstore[`U_BNE]   = 21'b0_1_1_0_00_0_0_1_0_0_0_0_0000_010_1;
        cstore[`U_JAL]   = 21'b0_0_0_1_10_0_0_0_1_0_0_0_0000_100_1;
        cstore[`U_JALR]  = 21'b0_1_0_1_10_0_0_0_1_1_0_1_0000_000_1;
    end

    assign ctrl = cstore[uaddr_r];
endmodule
