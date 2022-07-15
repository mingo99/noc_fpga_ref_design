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
# Specify Key for bitstream generation
# -------------------------------------------------------------------------
# Relative Path from ACE output directory : Speedster7t_2D_noc_ref_design_RD22/ac7t1550/build/results/ace
set_impl_option bitstream_encryption_aes_key_file "./../../../src/mem_init_files/aes_key.txt"

#-----------------------------------
#Impl options from passing run
#----------------------------------

# extra_effort_timing_optimization default: 0
set_impl_option extra_effort_timing_optimization 1

# gp_two_pass_mode default: 0
set_impl_option gp_two_pass_mode 1

# gp_util default: 0
set_impl_option gp_util 1

# mlp_merge default: 1
set_impl_option mlp_merge 0

# mt_pnr_opt default: 0
set_impl_option mt_pnr_opt 1

# resynthesis_move_ff_reset default: 0
set_impl_option resynthesis_move_ff_reset 1

# seed default: 42
set_impl_option seed 34

# single_tile_opt default: 0
set_impl_option single_tile_opt 1

