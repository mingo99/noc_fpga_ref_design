#######################################
# ACE GENERATED SDC FILE
# Generated on: 2021.01.18 at 09:22:46 GMT
# By: ACE 8.3
# From project: mlp_conv2d_top
#######################################
# IO Ring Boundary SDC File
#######################################

# Boundary clocks for clock_io_bank_ne

# Boundary clocks for gddr6_0

# Boundary clocks for gpio_bank_n

# Boundary clocks for noc

# Boundary clocks for pll_1

# Boundary clocks for pll_2
create_clock -period 1.6666666666666667 i_clk
# Frequency = 600.0 MHz
set_clock_uncertainty -setup 0.016666666666666666 [get_clocks i_clk]


######################################
# End IO Ring Boundary SDC File
######################################
