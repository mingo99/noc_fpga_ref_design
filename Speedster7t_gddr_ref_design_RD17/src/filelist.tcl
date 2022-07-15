set rtl_verilog_files {
default_nettype.v
random_seq_engine.sv
axi_pkt_gen.sv
axi_pkt_chk.sv
axi_nap_csr_master.sv
nap_slave_wrapper.sv
reset_processor.sv
gddr_ref_design_top.sv
}

# No VHDL files in project
# set rtl_vhdl_files {
# }

set synplify_constraints_files {
synplify_constraints.sdc
synplify_constraints.fdc
}

# ioring files must be first in the list as they specify the clocks
set ace_constraints_files {
../ioring/gddr_ref_design_top_ioring.sdc
../ioring/gddr_ref_design_top_ioring.pdc
../ioring/gddr_ref_design_top_ioring_util.xml
ace_constraints.sdc
ace_placements.pdc
}

set synplify_option_files {
synplify_options.tcl
}

set ace_options_files {
ace_options.tcl
}

set tb_verilog_files {
tb_noc_memory_behavioural.sv
tb_gddr_ref_design.sv
# When performing FULLCHIP_RTL simulations
# Add the GDDR model files here
}

set tb_vhdl_files {
}

# files relative to ace/ directory
set multi_acxip_files {
../acxip/gddr6_0.acxip
../acxip/gddr6_1.acxip
../acxip/gddr6_2.acxip
../acxip/gddr6_3.acxip
../acxip/gddr6_4.acxip
../acxip/gddr6_5.acxip
../acxip/gddr6_6.acxip
../acxip/gddr6_7.acxip
../acxip/noc.acxip
../acxip/pll.acxip
../acxip/pll_gddr_NE.acxip
../acxip/pll_gddr_NW.acxip
../acxip/functional_io.acxip
../acxip/ref_clk_io_NE.acxip
../acxip/ref_clk_io_NW.acxip
}  
