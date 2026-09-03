# CS-Senior Summer Session

Vivado FPGA project (Vivado 2024.2).

## Device

- Part: `xc7k70tfbv676-1`

## Project layout

```
project/          # Vivado project directory
  project.xpr     # Open this file in Vivado
```

## Getting started

1. Open `project/project.xpr` in Vivado 2024.2.
2. RTL is under `project/project.srcs/sources_1/new/` (top: `cpu_top`).
3. Testbench is under `project/project.srcs/sim_1/new/tb_cpu.v` (sim top: `tb_cpu`).
4. If sources are missing from the project, run `source add_sources.tcl` in the Vivado Tcl Console.
5. Run simulation: Flow Navigator → Simulation → Run Simulation.

This is a preliminary RV32I 5-stage pipeline with a microprogram control store. See `cpu_top.v` and `micro_ctrl.v`.

## Git notes

Generated Vivado outputs (cache, runs, bitstreams, logs) are ignored via `.gitignore`. Only source files, constraints, and the project file are tracked.
