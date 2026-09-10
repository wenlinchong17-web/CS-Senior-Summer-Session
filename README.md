# CS-Senior Summer Session

Vivado FPGA project (Vivado 2024.2).

## Device

- Part: `xc7a100tcsg324-1`（精工板 Artix-7 100T）

## Project layout

```
project/          # 唯一的 Vivado 工程
  project.xpr     # 用这个文件打开
```

## Getting started

1. Open `project/project.xpr` in Vivado 2024.2.
2. RTL is under `project/project.srcs/sources_1/new/` (synthesis top: `system_top`).
3. Testbenches are under `project/project.srcs/sim_1/new/` (`tb_cpu`, `tb_uart`).
4. If sources are missing from the project, run `source add_sources.tcl` in the Vivado Tcl Console.
5. Run simulation: set sim top to `tb_cpu` or `tb_uart`, then Flow Navigator → Simulation → Run Simulation.

RV32I 5-stage pipeline with a microprogram control store and UART MMIO. See `cpu_top.v`, `micro_ctrl.v`, and `system_top.v`.

## Git notes

Generated Vivado outputs (cache, runs, bitstreams, logs) are ignored via `.gitignore`. Only source files, constraints, and the project file are tracked.
