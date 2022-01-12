# global variables
set ::platform "zcu111"
set ::silicon "e"

# local variables
set project_dir "project"
set ip_dir "srcs/ip"
set constrs_dir "constrs"
set scripts_dir "scripts"

# set variable names
set part "xczu28dr-ffvg1517-2-${::silicon}"
set design_name "${::platform}_rfsoc_trd"
puts "INFO: Target part selected: '$part'"

# set up project
set_param board.repoPaths ./board_files
create_project $design_name $project_dir -part $part -force

set_property board_part xilinx.com:zcu111:part0:1.4 [current_project]

# set up IP repo
set_property ip_repo_paths $ip_dir [current_fileset]
update_ip_catalog -rebuild

# set up bd design
create_bd_design $design_name
source $scripts_dir/zcu111_rfsoc_trd_bd.tcl
validate_bd_design
regenerate_bd_layout -layout_file $scripts_dir/bd_layout.tcl
save_bd_design

set_msg_config -suppress -id {Vivado 12-4739}
set_msg_config -suppress -id {Constraints 18-4644}

# report IP core properties
file mkdir ./$project_dir/ip_prop
set c [get_ips ]
foreach x $c {
puts "[report_property $x -file ./$project_dir/ip_prop/$x.txt]"
}
# add hdl sources to project
make_wrapper -files [get_files ./$project_dir/zcu111_rfsoc_trd.srcs/sources_1/bd/zcu111_rfsoc_trd/zcu111_rfsoc_trd.bd] -top

add_files -norecurse ./$project_dir/zcu111_rfsoc_trd.srcs/sources_1/bd/zcu111_rfsoc_trd/hdl/zcu111_rfsoc_trd_wrapper.v
set_property top zcu111_rfsoc_trd_wrapper [current_fileset]
add_files -fileset constrs_1 -norecurse $constrs_dir/zcu111_rfsoc_trd_place.xdc
add_files -fileset constrs_1 -norecurse $constrs_dir/zcu111_rfsoc_trd_timing.xdc
add_files -fileset constrs_1 -norecurse $constrs_dir/leds.xdc
add_files -fileset constrs_1 -norecurse $constrs_dir/spi_pins.xdc
add_files -fileset constrs_1 -norecurse $constrs_dir/ddr_cons.xdc

set_property used_in_synthesis false [get_files  $constrs_dir/zcu111_rfsoc_trd_timing.xdc]
update_compile_order -fileset sources_1
# set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT 100 [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]


add_files -fileset utils_1 -norecurse $scripts_dir/opt_directive.tcl
set_property STEPS.OPT_DESIGN.TCL.PRE [ get_files $scripts_dir/opt_directive.tcl -of [get_fileset utils_1] ] [get_runs impl_1]
add_files -fileset utils_1 -norecurse $scripts_dir/post_route_phys_opt_directive_pre.tcl
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.PRE [ get_files $scripts_dir/post_route_phys_opt_directive_pre.tcl -of [get_fileset utils_1] ] [get_runs impl_1]
add_files -fileset utils_1 -norecurse $scripts_dir/post_route_phys_opt_directive_post.tcl
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST [ get_files $scripts_dir/post_route_phys_opt_directive_post.tcl -of [get_fileset utils_1] ] [get_runs impl_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sources_1
validate_bd_design
save_bd_design
update_compile_order -fileset sources_1
regenerate_bd_layout
save_bd_design

set proj_name [get_property NAME [current_project ]]
set proj_dir [get_property DIRECTORY [current_project ]]

puts "PASS_MSG: Block Design Successfully generated"

# report IP core properties
file mkdir $proj_dir/$proj_name.ip_prop
set c [get_ips ]
foreach x $c {
puts "[report_property $x -file $proj_dir/$proj_name.ip_prop/$x.txt]"
}

import_files
puts "PASS_MSG: Importing files to the design Successful"

reset_run synth_1
launch_runs synth_1 -jobs 20
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {   
    puts "ERROR: Synthesis failed"   
} else {
    puts "PASS_MSG: Synthesis finished Successfully"
    launch_runs impl_1 -to_step write_bitstream -jobs 20
    wait_on_run impl_1
    if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {   
        puts "ERROR: Implementation failed"   
    } else {
        puts "PASS_MSG: Implementation finished Successfully"

        #file mkdir $proj_dir/$proj_name.sdk
        #write_hw_platform -fixed -force  -include_bit -file $proj_dir/$proj_name.sdk/${proj_name}_wrapper.xsa
        write_hw_platform -fixed -force  -include_bit -file $proj_dir/${proj_name}_wrapper.xsa

        puts "PASS_MSG: XSA Generated Successfully"

    }
}

close_project
exit
