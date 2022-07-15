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
# set_impl_option speed_grade "C2"

# -------------------------------------------------------------------------
# Options from multiprocess that gave best timing results
# gp_param_fanout implementation gave the best timing
# -------------------------------------------------------------------------
set_impl_option fanout_limit 20
set_impl_option gp_ageing 0.87
set_impl_option gp_wt_range 100
set_impl_option placement_clone_flow 1
set_impl_option placement_optimization_iterations 6
set_impl_option seed 22

# Enable critical timeout to assist if required
# set_impl_option critical_fanout_limit 10


