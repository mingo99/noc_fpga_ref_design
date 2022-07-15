# -------------------------------------------------------------------------
# ACE options file
# Any setting here will override the default settings when the ACE project
# is build using the script flow
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# flow_mode default: evaluation
# -------------------------------------------------------------------------
set_impl_option flow_mode normal

# -------------------------------------------------------------------------
#  Option to set the bitstream ouput to hex 
# -------------------------------------------------------------------------
set_impl_option bitstream_output_hex  1

# -------------------------------------------------------------------------
# Do timing analysis across all three corners
# -------------------------------------------------------------------------
set_impl_option report_sweep_temperature_corners 1

# -------------------------------------------------------------------------
# Report unconstrained paths
# -------------------------------------------------------------------------
set_impl_option report_unconstrained_timing_paths 1

# -------------------------------------------------------------------------
# Option to set device speed grade
# -------------------------------------------------------------------------
# This would override the settings in the build scripts
set_impl_option speed_grade "C3"


# -------------------------------------------------------------------------
# Settings from MP run, autogen22
# -------------------------------------------------------------------------

# clock_skew_opt default: 0
set_impl_option clock_skew_opt 8

# design_style default: 0
set_impl_option design_style 1

# fast_connect_optimization default: 1
set_impl_option fast_connect_optimization 0

# gp_ignore_reset default: 0
set_impl_option gp_ignore_reset 1

# gp_two_pass_mode default: 0
set_impl_option gp_two_pass_mode 1

# gp_wt_range default: 65
set_impl_option gp_wt_range 100

# mlp_merge default: 1
set_impl_option mlp_merge 0

# placement_optimization_iterations default: 1
set_impl_option placement_optimization_iterations 6

# post_place_netlist_optimization_slack default: -9999
set_impl_option post_place_netlist_optimization_slack 0

# resynthesis_move_ff_reset default: 0
set_impl_option resynthesis_move_ff_reset 1

# target_utilization default: 68
set_impl_option target_utilization 70

