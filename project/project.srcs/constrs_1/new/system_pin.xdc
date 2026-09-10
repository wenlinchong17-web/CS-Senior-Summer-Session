# =========================================================
# 精工板 (Game Boy) 核心引脚物理约束文件
# 对应模块：system_top.v
# =========================================================

# 1. 系统时钟 (clk) -> T5
set_property PACKAGE_PIN T5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# 2. 系统复位 (rst_n) -> P15 (对应板子上的 S8 按键)
set_property PACKAGE_PIN P15 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# 3. UART 接收引脚 (rx, 连到电脑) -> N5
set_property PACKAGE_PIN N5 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]

# 4. UART 发送引脚 (tx, 连到电脑) -> T4
set_property PACKAGE_PIN T4 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

set_property SLEW SLOW [get_ports tx]

# 时钟复位与串口 (USB)
set_property PACKAGE_PIN T5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN P15 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property PACKAGE_PIN N5 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]
set_property PACKAGE_PIN T4 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

# 8个 LED 灯
set_property PACKAGE_PIN K2 [get_ports {led[0]}]
set_property PACKAGE_PIN J2 [get_ports {led[1]}]
set_property PACKAGE_PIN J3 [get_ports {led[2]}]
set_property PACKAGE_PIN H4 [get_ports {led[3]}]
set_property PACKAGE_PIN J4 [get_ports {led[4]}]
set_property PACKAGE_PIN G3 [get_ports {led[5]}]
set_property PACKAGE_PIN G4 [get_ports {led[6]}]
set_property PACKAGE_PIN F6 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# 8个拨码开关
set_property PACKAGE_PIN R1 [get_ports {switch[0]}]
set_property PACKAGE_PIN N4 [get_ports {switch[1]}]
set_property PACKAGE_PIN M4 [get_ports {switch[2]}]
set_property PACKAGE_PIN R2 [get_ports {switch[3]}]
set_property PACKAGE_PIN P2 [get_ports {switch[4]}]
set_property PACKAGE_PIN P3 [get_ports {switch[5]}]
set_property PACKAGE_PIN P4 [get_ports {switch[6]}]
set_property PACKAGE_PIN P5 [get_ports {switch[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switch[*]}]