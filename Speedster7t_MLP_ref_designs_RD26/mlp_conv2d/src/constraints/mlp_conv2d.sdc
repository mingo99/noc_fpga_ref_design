# Timing constraints MLP 2D Convolution

# Clock now defined in ioring SDC file
# Target currently 600MHz
# create_clock -name clk [get_ports i_clk] -period 1.666

# Need to multicycle the path in out_fifo where the data is muxed
if { [get_cells *mlp_multi_data_out*] != "" } {
    set_multicycle_path -from [get_pins *mlp_multi_data_out*/ck] -setup 2
    set_multicycle_path -from [get_pins *mlp_multi_data_out*/ck] -hold 1
    # Message only works in ACE, not Synplify as well
    # message "Multi-cycle path set"
}


