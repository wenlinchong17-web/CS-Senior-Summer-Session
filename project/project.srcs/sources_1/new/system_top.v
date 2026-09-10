`timescale 1ns / 1ps

module system_top(
    input wire clk,       
    input wire rst_n,     
    input wire rx,        
    output wire tx,
    output wire [7:0] led,    // 新增出板引脚
    input wire [7:0] switch   // 新增出板引脚
);

    (* mark_debug = "true" *) wire        mem_we;
    (* mark_debug = "true" *) wire [31:0] mem_addr;
    (* mark_debug = "true" *) wire [31:0] mem_wdata;
    (* mark_debug = "true" *) wire [31:0] mem_rdata;
    
    cpu_top u_cpu (
        .clk        (clk),
        .rst        (~rst_n),
        .mem_we_o   (mem_we),
        .mem_addr_o (mem_addr),
        .mem_wdata_o(mem_wdata),
        .mem_rdata_i(mem_rdata),
        .dbg_pc() 
    );

    wire is_mmio = (mem_addr[31:28] == 4'h8); 
    wire is_ram  = (mem_addr[31:28] == 4'h0);
    
    wire mmio_we = mem_we & is_mmio;
    wire ram_we  = mem_we & is_ram;
    
    wire [31:0] mmio_rdata;
    wire [31:0] ram_rdata;
    
    assign mem_rdata = is_mmio ? mmio_rdata : 
                       is_ram  ? ram_rdata : 32'd0;

    dmem u_dmem (
        .clk  (clk), .we   (ram_we), .addr (mem_addr),
        .wdata(mem_wdata), .rdata(ram_rdata)
    );

    // 例化新的多功能控制器
    mmio_controller u_mmio (
        .clk    (clk),
        .rst_n  (rst_n),
        .we_i   (mmio_we),
        .addr_i (mem_addr),
        .wdata_i(mem_wdata),
        .rdata_o(mmio_rdata),
        .rx     (rx),
        .tx     (tx),
        .led    (led),       // 连上
        .switch (switch)     // 连上
    );
endmodule