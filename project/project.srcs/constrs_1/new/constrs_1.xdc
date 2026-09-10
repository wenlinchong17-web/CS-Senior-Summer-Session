# xc7a100tcsg324-1  按实验 PPT I/O Ports（与 35T 同封装，管脚兼容）
# 顶层端口：clk / rst_n / rx / tx
# 板上实测更接近 100 MHz：周期 10 ns，UART 分频 100e6/115200 ≈ 868

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property PACKAGE_PIN T5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

# I_rst_n → P15，板上复位键 S8，低有效
set_property PACKAGE_PIN P15 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# I_rs232_rxd → N5，FPGA 串口接收（PC 发给板子）
set_property PACKAGE_PIN N5 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]
set_property PULLUP true [get_ports rx]

# O_rs232_txd → T4，FPGA 串口发送（板子发给 PC）
set_property PACKAGE_PIN T4 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]
