# Options to set batch size
# This version is for 60x40 MLP, which should use all NAPs in the fabric
# Currently test with just 4 instances
set_option -hdl_param -set BATCH 60
set_option -hdl_param -set NUM_ROWS 4
set_option -hdl_param -set NUM_COLS 10

# Ensure correct top level is set
set_option -top_module "mlp_conv2d_top_chip"

