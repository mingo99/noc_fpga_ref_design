# -------------------------------------------------------------------------
# Synplify options file
# Any setting here will override the default settings when the Synplify Pro
# project is build using the script flow
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# Define the top level
# -------------------------------------------------------------------------
set_option -top_module "gddr_ref_design_top"
set_option -retiming 1
set_option -resource_sharing 0
set_option -write_verilog 1
# -------------------------------------------------------------------------
# Example of how to set a top level parameter
# -------------------------------------------------------------------------
# set_option -hdl_param -set MY_PARAM 60

# -------------------------------------------------------------------------
# Example of how to set a define
# -------------------------------------------------------------------------
# set_option -hdl_define -set DEVICE_7t1500=1

# -------------------------------------------------------------------------
# Set the default frequency for undefined clocks
# -------------------------------------------------------------------------
set_option -frequency 500

# -------------------------------------------------------------------------
# Example of how to set the maximum fanout
# -------------------------------------------------------------------------
set_option -maxfan 95

