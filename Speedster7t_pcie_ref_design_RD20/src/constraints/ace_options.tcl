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
# Option to run flow through to generating a bitstream
# -------------------------------------------------------------------------
set_impl_option flow_mode normal

# -------------------------------------------------------------------------
# Options from multiprocess to give best performance
# -------------------------------------------------------------------------
# Option was autogen18_fpec

# cleanup_fanout_buffers default: 0
set_impl_option cleanup_fanout_buffers 1

# extra_placement_optimization default: 1
set_impl_option extra_placement_optimization 0

# fanout_limit default: 95
set_impl_option fanout_limit 48

# post_place_using_graph_matching default: 4
set_impl_option post_place_using_graph_matching 0


