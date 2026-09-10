`include "rv32_defines.vh"

// RV32I 五级流水线 CPU：IF -> ID -> EX -> MEM -> WB
// 控制器为微程序 ROM；控制字从 ID 读出后随流水线寄存器向后传递。
module cpu_top (
    input  wire        clk,
    input  wire        rst,

    // ======== 新增：数据总线接口 ========
    output wire        mem_we_o,    // CPU写使能
    output wire        mem_re_o,    // CPU读使能（UART 清 rx_ready 用）
    output wire [31:0] mem_addr_o,  // CPU想访问的地址
    output wire [31:0] mem_wdata_o, // CPU想写出的数据
    input  wire [31:0] mem_rdata_i, // 外部给CPU读入的数据
    // ====================================

    output wire [31:0] dbg_pc,
    output wire        dbg_stall,
    output wire        dbg_flush,
    output wire [31:0] dbg_reg_data,
    input  wire [4:0]  dbg_reg_addr,
    output wire [4:0]  dbg_uaddr,
    output wire        dbg_overflow,
    output wire [31:0] dbg_epc,
    output wire [31:0] dbg_perf_cycles,
    output wire [31:0] dbg_perf_inst,
    output wire [31:0] dbg_perf_stall,
    output wire [31:0] dbg_perf_flush
);
    // =========================================================================
    // IF
    // =========================================================================
    wire        stall;
    wire        if_id_flush;
    wire        id_ex_flush;
    wire        pc_redirect;
    wire [31:0] pc_target;

    reg  [31:0] pc_f = 32'd0;
    wire [31:0] pc_plus4_f = pc_f + 32'd4;
    wire [31:0] inst_f;

    wire [31:0] pc_next = pc_redirect ? pc_target : pc_plus4_f;

    always @(posedge clk) begin
        if (rst)
            pc_f <= 32'd0;
        else if (!stall)
            pc_f <= pc_next;
    end

    imem u_imem (
        .addr(pc_f),
        .inst(inst_f)
    );

    // =========================================================================
    // IF/ID
    // =========================================================================
    reg [31:0] inst_d;
    reg [31:0] pc_d;
    reg [31:0] pc_plus4_d;

    always @(posedge clk) begin
        if (rst || if_id_flush) begin
            inst_d     <= `NOP_INST;
            pc_d       <= 32'd0;
            pc_plus4_d <= 32'd0;
        end else if (!stall) begin
            inst_d     <= inst_f;
            pc_d       <= pc_f;
            pc_plus4_d <= pc_plus4_f;
        end
    end

    // =========================================================================
    // ID：拆字段、查微程序、读寄存器、生成立即数
    // =========================================================================
    wire [6:0] opcode_d = inst_d[6:0];
    wire [2:0] funct3_d = inst_d[14:12];
    wire [6:0] funct7_d = inst_d[31:25];
    wire [4:0] rd_d     = inst_d[11:7];
    wire [4:0] rs1_d    = inst_d[19:15];
    wire [4:0] rs2_d    = inst_d[24:20];

    wire [4:0]           uaddr_d;
    wire [`CTRL_W-1:0]   ctrl_d;

    micro_ctrl u_micro (
        .opcode (opcode_d),
        .funct3 (funct3_d),
        .funct7 (funct7_d),
        .uaddr  (uaddr_d),
        .ctrl   (ctrl_d)
    );

    wire [31:0] imm_d;
    imm_gen u_imm (
        .inst   (inst_d),
        .imm_sel(ctrl_d[`C_IMMSEL]),
        .imm    (imm_d)
    );

    wire        we_w;
    wire [4:0]  rd_w;
    wire [31:0] result_w;
    wire [31:0] rs1_data_d;
    wire [31:0] rs2_data_d;

    regfile u_regfile (
        .clk(clk),
        .we (we_w),
        .wa (rd_w),
        .wd (result_w),
        .ra1(rs1_d),
        .ra2(rs2_d),
        .rd1(rs1_data_d),
        .rd2(rs2_data_d),
        .ra3(dbg_reg_addr),
        .rd3(dbg_reg_data)
    );

    // =========================================================================
    // ID/EX
    // =========================================================================
    reg [`CTRL_W-1:0] ctrl_e;
    reg [31:0]        pc_e;
    reg [31:0]        pc_plus4_e;
    reg [31:0]        rs1_data_e;
    reg [31:0]        rs2_data_e;
    reg [31:0]        imm_e;
    reg [4:0]         rs1_e;
    reg [4:0]         rs2_e;
    reg [4:0]         rd_e;
    reg [2:0]         funct3_e;

    always @(posedge clk) begin
        if (rst || id_ex_flush || stall) begin
            ctrl_e      <= {`CTRL_W{1'b0}};
            pc_e        <= 32'd0;
            pc_plus4_e  <= 32'd0;
            rs1_data_e  <= 32'd0;
            rs2_data_e  <= 32'd0;
            imm_e       <= 32'd0;
            rs1_e       <= 5'd0;
            rs2_e       <= 5'd0;
            rd_e        <= 5'd0;
            funct3_e    <= 3'd0;
        end else begin
            ctrl_e      <= ctrl_d;
            pc_e        <= pc_d;
            pc_plus4_e  <= pc_plus4_d;
            rs1_data_e  <= rs1_data_d;
            rs2_data_e  <= rs2_data_d;
            imm_e       <= imm_d;
            rs1_e       <= rs1_d;
            rs2_e       <= rs2_d;
            rd_e        <= rd_d;
            funct3_e    <= funct3_d;
        end
    end

    // =========================================================================
    // EX：旁路、ALU、分支/跳转目标
    // =========================================================================
    wire        we_m;
    wire [4:0]  rd_m;
    wire [31:0] alu_m;
    wire [1:0]  forward_a;
    wire [1:0]  forward_b;

    forwarding u_fwd (
        .ex_mem_regwrite(we_m),
        .mem_wb_regwrite(we_w),
        .ex_mem_rd      (rd_m),
        .mem_wb_rd      (rd_w),
        .id_ex_rs1      (rs1_e),
        .id_ex_rs2      (rs2_e),
        .forward_a      (forward_a),
        .forward_b      (forward_b)
    );

    wire [31:0] fwd_rs1 =
        (forward_a == 2'b10) ? alu_m :
        (forward_a == 2'b01) ? result_w : rs1_data_e;
    wire [31:0] fwd_rs2 =
        (forward_b == 2'b10) ? alu_m :
        (forward_b == 2'b01) ? result_w : rs2_data_e;

    wire [31:0] alu_a = ctrl_e[`C_ALUSRCA] ? pc_e   : fwd_rs1;
    wire [31:0] alu_b = ctrl_e[`C_ALUSRCB] ? imm_e  : fwd_rs2;

    wire [31:0] alu_y_e;
    wire        alu_ov_e;
    alu u_alu (
        .a     (alu_a),
        .b     (alu_b),
        .alu_op(ctrl_e[`C_ALUOP]),
        .y     (alu_y_e),
        .ov    (alu_ov_e)
    );

    wire        ov_exc_e = ctrl_e[`C_CHKOV] && alu_ov_e && ctrl_e[`C_VALID];

    wire        eq_e     = (fwd_rs1 == fwd_rs2);
    wire        taken_e  = ctrl_e[`C_BRANCH] &&
                           ((funct3_e == 3'b000 &&  eq_e) ||
                            (funct3_e == 3'b001 && !eq_e));
    wire        jump_e   = ctrl_e[`C_JUMP];
    assign      pc_redirect = jump_e || taken_e || ov_exc_e;

    wire [31:0] br_target = pc_e + imm_e;
    wire [31:0] jr_target = {alu_y_e[31:1], 1'b0};
    assign pc_target = ov_exc_e ? `OV_HANDLER :
                       (jump_e && ctrl_e[`C_JUMPSRC]) ? jr_target : br_target;

    reg [31:0] epc;
    reg        ov_sticky;
    always @(posedge clk) begin
        if (rst) begin
            epc       <= 32'd0;
            ov_sticky <= 1'b0;
        end else if (ov_exc_e) begin
            epc       <= pc_e;
            ov_sticky <= 1'b1;
        end
    end

    wire [31:0] store_data_e = fwd_rs2;

    // =========================================================================
    // EX/MEM
    // =========================================================================
    reg [`CTRL_W-1:0] ctrl_m;
    reg [31:0]        pc_plus4_m;
    reg [31:0]        store_data_m;
    reg [4:0]         rd_m_r;
    reg [31:0]        alu_m_r;

    always @(posedge clk) begin
        if (rst || ov_exc_e) begin
            ctrl_m       <= {`CTRL_W{1'b0}};
            pc_plus4_m   <= 32'd0;
            store_data_m <= 32'd0;
            rd_m_r       <= 5'd0;
            alu_m_r      <= 32'd0;
        end else begin
            ctrl_m       <= ctrl_e;
            pc_plus4_m   <= pc_plus4_e;
            store_data_m <= store_data_e;
            rd_m_r       <= rd_e;
            alu_m_r      <= alu_y_e;
        end
    end

    assign we_m  = ctrl_m[`C_REGWRITE];
    assign rd_m  = rd_m_r;
    assign alu_m = alu_m_r;

    // =========================================================================
    // MEM 级：将原先内部的 dmem 移除，将信号引出到外部总线
    // =========================================================================
    assign mem_we_o    = ctrl_m[`C_MEMWRITE]; // 把写使能送出去
    assign mem_re_o    = ctrl_m[`C_MEMREAD];
    assign mem_addr_o  = alu_m_r;             // 把地址送出去
    assign mem_wdata_o = store_data_m;        // 把要写的数据送出去
    
    wire [31:0] dmem_rdata_m = mem_rdata_i;   // 接收外面传进来的数据

    // =========================================================================
    // MEM/WB
    // =========================================================================
    reg [`CTRL_W-1:0] ctrl_w;
    reg [31:0]        pc_plus4_w;
    reg [31:0]        alu_w;
    reg [31:0]        rdata_w;
    reg [4:0]         rd_w_r;

    always @(posedge clk) begin
        if (rst) begin
            ctrl_w     <= {`CTRL_W{1'b0}};
            pc_plus4_w <= 32'd0;
            alu_w      <= 32'd0;
            rdata_w    <= 32'd0;
            rd_w_r     <= 5'd0;
        end else begin
            ctrl_w     <= ctrl_m;
            pc_plus4_w <= pc_plus4_m;
            alu_w      <= alu_m_r;
            rdata_w    <= dmem_rdata_m;
            rd_w_r     <= rd_m_r;
        end
    end

    assign we_w = ctrl_w[`C_REGWRITE];
    assign rd_w = rd_w_r;

    assign result_w =
        (ctrl_w[`C_MEMTOREG] == `MTR_MEM) ? rdata_w :
        (ctrl_w[`C_MEMTOREG] == `MTR_PC4) ? pc_plus4_w :
                                            alu_w;

    // =========================================================================
    // 冒险单元
    // =========================================================================
    hazard u_hazard (
        .id_ex_memread(ctrl_e[`C_MEMREAD]),
        .id_ex_rd     (rd_e),
        .if_id_use_rs1(ctrl_d[`C_USERS1]),
        .if_id_use_rs2(ctrl_d[`C_USERS2]),
        .if_id_rs1    (rs1_d),
        .if_id_rs2    (rs2_d),
        .pc_redirect  (pc_redirect),
        .stall        (stall),
        .if_id_flush  (if_id_flush),
        .id_ex_flush  (id_ex_flush)
    );

    assign dbg_pc       = pc_f;
    assign dbg_stall    = stall;
    assign dbg_flush    = pc_redirect;
    assign dbg_uaddr    = uaddr_d;
    assign dbg_overflow = ov_sticky;
    assign dbg_epc      = epc;

    // -------------------------------------------------------------------------
    // 性能计数：复位结束后开始，停机指令提交后冻结。
    // 提交 = 到达 WB 且产生体系结构效果（不含气泡和 flush 插入的 addi x0,x0,0）。
    // -------------------------------------------------------------------------
    wire wb_commit = ctrl_w[`C_VALID] &&
                     ((ctrl_w[`C_REGWRITE] && (rd_w != 5'd0)) ||
                      ctrl_w[`C_MEMWRITE] ||
                      ctrl_w[`C_BRANCH]   ||
                      ctrl_w[`C_JUMP]);
    wire wb_halt   = ctrl_w[`C_JUMP] && !ctrl_w[`C_JUMPSRC] &&
                     (rd_w == 5'd0) && (pc_plus4_w == `HALT_PC4);

    reg        perf_run;
    reg [31:0] perf_cycles;
    reg [31:0] perf_inst;
    reg [31:0] perf_stall;
    reg [31:0] perf_flush;

    always @(posedge clk) begin
        if (rst) begin
            perf_run    <= 1'b1;
            perf_cycles <= 32'd0;
            perf_inst   <= 32'd0;
            perf_stall  <= 32'd0;
            perf_flush  <= 32'd0;
        end else if (perf_run) begin
            perf_cycles <= perf_cycles + 32'd1;
            if (wb_commit)
                perf_inst <= perf_inst + 32'd1;
            if (stall)
                perf_stall <= perf_stall + 32'd1;
            if (pc_redirect)
                perf_flush <= perf_flush + 32'd1;
            if (wb_halt)
                perf_run <= 1'b0;
        end
    end

    assign dbg_perf_cycles = perf_cycles;
    assign dbg_perf_inst   = perf_inst;
    assign dbg_perf_stall  = perf_stall;
    assign dbg_perf_flush  = perf_flush;
endmodule
