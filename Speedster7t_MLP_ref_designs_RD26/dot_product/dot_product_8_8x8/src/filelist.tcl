set rtl_verilog_files {
    default_nettype.v
    dot_product_8_8x8.sv
    dot_product_8_8x8_top.sv
}

set ace_constraints_files {
    ace_timing.sdc
}

set ace_impl_option_files {
}

set synplify_constraints_files {
    ace_timing.sdc
}

set synplify_option_files {
}

set tb_verilog_files {
# included:
#    test_sequence.vh
    tb_dot_product_8_8x8.sv
}

