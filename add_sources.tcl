# 在 Vivado Tcl Console 中执行:
#   cd {D:/VivadoExperiment/CS-Senior Summer Session/project}
#   source ../add_sources.tcl
# 或打开本工程后:
#   source {D:/VivadoExperiment/CS-Senior Summer Session/add_sources.tcl}

set src_dir [file normalize [file join [file dirname [info script]] project/project.srcs/sources_1/new]]
set sim_dir [file normalize [file join [file dirname [info script]] project/project.srcs/sim_1/new]]

add_files -norecurse [glob -nocomplain $src_dir/*.v]
add_files -norecurse [glob -nocomplain $src_dir/*.vh]
set_property file_type "Verilog Header" [get_files $src_dir/rv32_defines.vh]
set_property is_global_include true [get_files $src_dir/rv32_defines.vh]

add_files -fileset sim_1 -norecurse [glob -nocomplain $sim_dir/*.v]

set_property top cpu_top [current_fileset]
set_property top tb_cpu [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "RTL and testbench added. Top: cpu_top / tb_cpu"
