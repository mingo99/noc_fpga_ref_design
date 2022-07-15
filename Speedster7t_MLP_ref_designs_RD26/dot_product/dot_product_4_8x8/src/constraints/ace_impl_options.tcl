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
# If the design is modified, then multiprocess may need re-running to get
# the best new options.  These options can then be included here
# -------------------------------------------------------------------------
set_impl_option balance_clock "0"
set_impl_option fanout_limit "48"
set_impl_option gp_spreading_factor "2"
set_impl_option seed "21"

