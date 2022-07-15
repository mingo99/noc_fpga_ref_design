set rtl_verilog_files {
default_nettype.v
random_seq_engine.sv
axi_pkt_gen.sv
axi_pkt_chk.sv
nap_slave_wrapper.sv
reset_processor.sv
axi_nap_csr_master_ddr.sv
ddr4_training_polling_block.sv
ddr4_ref_design_top.sv
}

# No VHDL files in project
# set rtl_vhdl_files {
# }

set synplify_constraints_files {
synplify_constraints.sdc
synplify_constraints.fdc
}

# ioring files must be first as they specify the clocks
set ace_constraints_files {
../ioring/ddr4_ref_design_top_ioring.sdc
../ioring/ddr4_ref_design_top_ioring.pdc
../ioring/ddr4_ref_design_top_ioring_util.xml
ace_constraints.sdc
ace_placements.pdc
}

set synplify_option_files {
synplify_options.tcl
}

set ace_options_files {
ace_options.tcl
}

set multi_acxip_files {
../acxip/ddr4_1.acxip
../acxip/noc_1.acxip
../acxip/pll_1.acxip
../acxip/pll_2.acxip
../acxip/clock_io_se.acxip
../acxip/clock_io_sw.acxip
../acxip/gpio_1.acxip
}

# Uncomment the lines below with path micron/protected_vcs/* if using Micron model and simulating with VCS
# Uncomment the lines below with path micron/protected_modelsim/* if using Micron model and simulating with Questa
# Uncomment the line below skhynix/ddr4_vcs.vp if using SKHynix model and simulating with VCS
# Uncomment the line below skhynix/ddr4_modelsim.vp if using SKHynix model and simulating with Questa

set tb_verilog_files {
tb_noc_memory_behavioural.sv
# micron/protected_vcs/arch_package.sv
# micron/protected_vcs/proj_package.sv
# micron/protected_vcs/dimm_interface.sv
# micron/protected_vcs/StateTable.svp
# micron/protected_vcs/MemoryArray.svp
# micron/protected_vcs/ddr4_model.svp
# micron/protected_modelsim/arch_package.sv
# micron/protected_modelsim/proj_package.sv
# micron/protected_modelsim/dimm_interface.sv
# micron/protected_modelsim/StateTable.svp
# micron/protected_modelsim/MemoryArray.svp
# micron/protected_modelsim/ddr4_model.svp
# skhynix/ddr4_vcs.vp
# skhynix/ddr4_modelsim.vp
tb_ddr4_ref_design.sv
}

set tb_vhdl_files {
}


