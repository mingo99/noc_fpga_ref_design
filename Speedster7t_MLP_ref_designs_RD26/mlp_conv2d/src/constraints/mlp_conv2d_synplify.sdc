# Timing constraints MLP 2D Convolution

# Set 600MHz target
create_clock -name clk [get_ports i_clk] -period 1.66

# Need to multicycle the path in out_fifo where the data is muxed
if { [get_cells *mlp_multi_data_out*] != "" } {
    set_multicycle_path -from *mlp_multi_data_out* -setup 2
    set_multicycle_path -from *mlp_multi_data_out* -hold 1
}


