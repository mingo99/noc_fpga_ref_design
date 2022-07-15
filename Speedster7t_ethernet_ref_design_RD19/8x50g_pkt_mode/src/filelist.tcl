
set rtl_verilog_files {
default_nettype.v
nap_ethernet_wrapper.sv
random_seq_engine.sv
reset_processor.sv
eth_pkt_gen.sv
eth_pkt_chk.sv
eth_fifo_256x512k.sv
eth_rx_4way_switch.sv
tx_100g_rate_limit.sv
ethernet_8x50g_pkt_mode_top.sv
}

set synplify_constraints_files {
synplify_constraints.sdc
synplify_constraints.fdc
}

set ace_constraints_files {
../ioring/ethernet_8x50g_pkt_mode_top_ioring.sdc
../ioring/ethernet_8x50g_pkt_mode_top_ioring.pdc
ace_constraints.sdc
ace_placements.pdc
../ioring/ethernet_8x50g_pkt_mode_top_ioring_util.xml
}

set synplify_option_files {
synplify_options.tcl
}

set ace_options_files {
ace_options.tcl
}

set tb_verilog_files {
tb_eth_monitor.sv
tb_ethernet_ref_design.sv
}

set tb_vhdl_files {
}

set multi_acxip_files {
../acxip/clock_io.acxip
../acxip/noc_1.acxip
../acxip/ethernet_1.acxip
../acxip/gpio_n0.acxip
../acxip/gpio_n1.acxip
../acxip/gpio_n2.acxip
../acxip/gpio_s0.acxip
../acxip/gpio_s1.acxip
../acxip/pll_noc.acxip
../acxip/pll_eth_ref.acxip
../acxip/pll_eth_ff.acxip
../acxip/pll_usr.acxip
}


