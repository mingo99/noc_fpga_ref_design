# -------------------------------------------------------------------------
# ACE options file
# Any setting here will override the default settings when the ACE project
# is build using the script flow
# -------------------------------------------------------------------------

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
set_impl_option speed_grade "C2"

# -------------------------------------------------------------------------
# Options from multiprocess to give best timing performance
# If there are significant changes to either the design or build flow
# then multiprocess will need to be re-run and a new set of options determined
# -------------------------------------------------------------------------
set_impl_option gp_two_pass_mode "1"
set_impl_option resynthesis_retime_flops "2"
set_impl_option seed "34"
set_impl_option target_utilization "50"

