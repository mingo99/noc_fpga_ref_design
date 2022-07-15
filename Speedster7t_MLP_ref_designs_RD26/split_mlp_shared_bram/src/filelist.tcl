#    ram_width_encoding.sv

set rtl_verilog_files {
    default_nettype.sv
    pipeline.sv
    group_2_mlp_1_bram.sv
    split_mlp_shared_bram_stack.sv
    split_mlp_shared_bram.sv
}

set synplify_constraints_files {
    ace_timing.sdc
}

set synplify_option_files {
}

set tb_verilog_files {
    tb_split_mlp_shared_bram.sv
}

set mem_init_files {
    matrix_a.txt
    matrix_b.txt
}

set ace_constraints_files {
    ace_timing.sdc
}

set ace_options_files {
    ace_impl_options.tcl
}

