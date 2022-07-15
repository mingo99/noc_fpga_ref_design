#######################################
# ACE GENERATED SDC FILE
# Generated on: 2020.07.24 at 11:21:24 BST
# By: ACE 8.2
# From project: ethernet_8x50g_pkt_mode_top
#######################################
# IO Ring Boundary SDC File
#######################################

# Boundary clocks for clock_io

# Boundary clocks for ethernet_1
create_clock -period 2.2222222222222223 ethernet_1_ref_clk_divby2
# Frequency = 450.0 MHz
set_clock_uncertainty -setup 0.022222222222222223 [get_clocks ethernet_1_ref_clk_divby2]

create_clock -period 2.5 ethernet_1_m0_ff_clk_divby2
# Frequency = 400.0 MHz
set_clock_uncertainty -setup 0.025 [get_clocks ethernet_1_m0_ff_clk_divby2]

create_clock -period 2.5 ethernet_1_m1_ff_clk_divby2
# Frequency = 400.0 MHz
set_clock_uncertainty -setup 0.025 [get_clocks ethernet_1_m1_ff_clk_divby2]


# Boundary clocks for gpio_n0

# Boundary clocks for gpio_n1

# Boundary clocks for gpio_n2

# Boundary clocks for gpio_s0

# Boundary clocks for gpio_s1

# Boundary clocks for noc_1

# Boundary clocks for pll_eth_ff

# Boundary clocks for pll_eth_ref

# Boundary clocks for pll_noc

# Boundary clocks for pll_usr
create_clock -period 1.972386587793287 i_eth_clk
# Frequency = 506.9999999943234 MHz
set_clock_uncertainty -setup 0.01972386587793287 [get_clocks i_eth_clk]


######################################
# End IO Ring Boundary SDC File
######################################
