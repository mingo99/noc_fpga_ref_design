set rtl_verilog_files {
    default_nettype.v
    bram_deep_w.sv
    lram_wr_ctrl.sv
    mlp_bram_lramin_casc.sv
    mvm_8mlp_16int8_earlyout.sv
    mvm_8mlp_16int8_earlyout_top.sv
}

set ace_constraints_files {
    ace_timing.sdc
}

set ace_impl_option_files {
#    ace_options.tcl
}

set synplify_constraints_files {
    ace_timing.sdc
}

set synplify_option_files {
}

set tb_verilog_files {
# included files
#   test_sequence.vh
#   matrix.svh
    tb_mvm_8mlp_16int8_earlyout.sv
}

