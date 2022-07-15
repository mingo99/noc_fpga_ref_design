#######################################
# ACE GENERATED SDC FILE
# Generated on: 2020.10.19 at 10:42:09 PDT
# By: ACE 8.2.1
# From project: ddr4_ref_design_top
#######################################
# IO Ring Boundary SDC File
#######################################

# Boundary clocks for clock_io_se

# Boundary clocks for clock_io_sw

# Boundary clocks for ddr4_1
create_clock -period 2.5 ddr4_1_clk
# Frequency = 400.0 MHz
set_clock_uncertainty -setup 0.025 [get_clocks ddr4_1_clk]

create_clock -period 2.5 ddr4_1_clk_alt[0]
# Frequency = 400.0 MHz
set_clock_uncertainty -setup 0.025 [get_clocks ddr4_1_clk_alt[0]]

create_clock -period 2.5 ddr4_1_clk_alt[1]
# Frequency = 400.0 MHz
set_clock_uncertainty -setup 0.025 [get_clocks ddr4_1_clk_alt[1]]


# Boundary clocks for gpio_1

# Boundary clocks for noc_1

# Boundary clocks for pll_1

# Boundary clocks for pll_2
create_clock -period 2.0 i_clk
# Frequency = 500.0 MHz
set_clock_uncertainty -setup 0.02 [get_clocks i_clk]

create_clock -period 4.0 i_training_clk
# Frequency = 250.0 MHz
set_clock_uncertainty -setup 0.04 [get_clocks i_training_clk]


######################################
# End IO Ring Boundary SDC File
######################################
