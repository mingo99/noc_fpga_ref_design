#######################################
# ACE GENERATED SDC FILE
# Generated on: 2020.09.22 at 09:25:47 PDT
# By: ACE 8.2.1
# From project: gddr_ref_design_top
#######################################
# IO Ring Boundary SDC File
#######################################

# Boundary clocks for functional_io

# Boundary clocks for gddr6_0

# Boundary clocks for gddr6_1
create_clock -period 2.0 gddr6_1_dc0_clk
# Frequency = 500.0 MHz
set_clock_uncertainty -setup 0.02 [get_clocks gddr6_1_dc0_clk]


# Boundary clocks for gddr6_2
create_clock -period 2.0 gddr6_2_dc0_clk
# Frequency = 500.0 MHz
set_clock_uncertainty -setup 0.02 [get_clocks gddr6_2_dc0_clk]


# Boundary clocks for gddr6_3

# Boundary clocks for gddr6_4

# Boundary clocks for gddr6_5
create_clock -period 2.0 gddr6_5_dc0_clk
# Frequency = 500.0 MHz
set_clock_uncertainty -setup 0.02 [get_clocks gddr6_5_dc0_clk]


# Boundary clocks for gddr6_6
create_clock -period 2.0 gddr6_6_dc0_clk
# Frequency = 500.0 MHz
set_clock_uncertainty -setup 0.02 [get_clocks gddr6_6_dc0_clk]


# Boundary clocks for gddr6_7

# Boundary clocks for noc

# Boundary clocks for pll
create_clock -period 2.0 i_clk
# Frequency = 500.0 MHz
set_clock_uncertainty -setup 0.02 [get_clocks i_clk]


# Boundary clocks for pll_gddr_NE

# Boundary clocks for pll_gddr_NW

# Boundary clocks for ref_clk_io_NE

# Boundary clocks for ref_clk_io_NW

######################################
# End IO Ring Boundary SDC File
######################################
