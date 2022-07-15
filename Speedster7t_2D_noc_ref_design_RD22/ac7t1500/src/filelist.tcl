
set rtl_verilog_files {
default_nettype.v
random_seq_engine.sv
reset_processor_v2.sv
nap_horizontal_wrapper.sv
nap_vertical_wrapper.sv
nap_slave_wrapper.sv
nap_master_wrapper.sv    
data_stream_pkt_gen.sv
data_stream_pkt_chk.sv
axi_pkt_gen.sv
axi_pkt_chk.sv
axi_bram_responder.sv
shift_reg.sv
reg_control_block.sv
noc_2d_ref_design_top.sv
}

# No VHDL files in project
# set rtl_vhdl_files {
# }

set synplify_constraints_files {
synplify_constraints.sdc
synplify_constraints.fdc
}

set ace_constraints_files {
../ioring/noc_2d_ref_design_top_ioring.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_850mV_0C_fast.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_850mV_0C_slow.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_850mV_n40C_fast.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_850mV_n40C_slow.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_850mV_125C_fast.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_850mV_125C_slow.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_750mV_0C_fast.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_750mV_0C_slow.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_750mV_n40C_fast.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_750mV_n40C_slow.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_750mV_125C_fast.sdc
../ioring/noc_2d_ref_design_top_ioring_delays_C3_750mV_125C_slow.sdc
../ioring/noc_2d_ref_design_top_ioring.pdc
ace_constraints.sdc
ace_placements.pdc
../ioring/noc_2d_ref_design_top_ioring_bitstream0.hex
../ioring/noc_2d_ref_design_top_ioring_bitstream1.hex
../ioring/noc_2d_ref_design_top_ioring_util.xml
}

set generate_ioring_path "../ioring"

set synplify_option_files {
synplify_options.tcl
}

set ace_options_files {
ace_options.tcl
}

# files relative to ace/ directory
set multi_acxip_files {
../acxip/noc_2d.acxip
../acxip/pll_send_clk.acxip
../acxip/pll_chk_clk.acxip

# VP Rev 1 files
../acxip/vp_clkio_ne.acxip
../acxip/vp_clkio_nw.acxip
../acxip/vp_clkio_se.acxip
../acxip/vp_clkio_sw.acxip
../acxip/vp_gpio_n_b2.acxip
../acxip/vp_gpio_n_b0.acxip
../acxip/vp_gpio_n_b1.acxip
../acxip/vp_gpio_s_b0.acxip
../acxip/vp_gpio_s_b1.acxip
../acxip/vp_gpio_s_b2.acxip
../acxip/vp_pll_nw_2.acxip
../acxip/vp_pll_sw_2.acxip
}    

set tb_verilog_files {
tb_noc_2d_ref_design.sv
}

set tb_vhdl_files {
}

