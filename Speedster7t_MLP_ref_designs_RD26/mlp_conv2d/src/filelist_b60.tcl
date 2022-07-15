set rtl_verilog_files {
default_nettype.v
mlp_wrapper_multi.sv
dot_product_16_8x8_multi.sv
nap_slave_wrapper.sv
dataflow_control.sv
line_fifo.sv
out_fifo.sv
reset_processor.sv
mlp_conv2d_top.sv
}

set rtl_vhdl_files {
}

set synplify_constraints_files {
mlp_conv2d_synplify.sdc
mlp_conv2d.fdc
}

set ace_constraints_files {
../ioring/mlp_conv2d_top_ioring.sdc
../ioring/mlp_conv2d_top_ioring.pdc
../ioring/mlp_conv2d_top_ioring_util.xml
mlp_conv2d.sdc
mlp_conv2d_b60.pdc
}

set synplify_option_files {
synplify_options_b60.tcl
}

set ace_options_files {
ace_impl_options.tcl
}

set nl_verilog_files {
}

# IP files
set multi_acxip_files {
../acxip/noc.acxip
../acxip/pll_1.acxip
../acxip/pll_2.acxip
../acxip/gpio_bank_n.acxip
../acxip/clock_io_bank_ne.acxip
../acxip/gddr6_0.acxip
}

set tb_verilog_files {
tb_mlp_behavioural_16x_int8.sv
tb_axi_mem_checker.sv
tb_noc_memory_behavioural.sv
tb_mlp_conv2d.sv
}

set tb_vhdl_files {
}
