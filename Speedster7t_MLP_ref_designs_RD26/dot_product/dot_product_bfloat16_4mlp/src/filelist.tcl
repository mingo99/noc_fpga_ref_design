set rtl_verilog_files {
    default_nettype.v
    mlp_stack.sv
    dot_product_bfloat16_4mlp_top.sv
}

set ace_constraints_files {
    ace_timing.sdc
}

set ace_impl_option_files {
    ace_options.tcl
}

set synplify_constraints_files {
    ace_timing.sdc
}

set synplify_option_files {
}

set tb_verilog_files {
    tb_pipeline.sv
    tb_dot_product_bfloat16_4mlp.sv
}

