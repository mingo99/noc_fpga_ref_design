# -------------------------------------------------------------------------
# Synplify timing constaint file
# All clocks and clock relationships should be defined in this file for synthesis
# Note : There are small differences between Synplify Pro and ACE SDC syntax
# therefore it is not recommended to use the same file for both, instead to
# have two separate files.
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# Primary clock timing constraints
# -------------------------------------------------------------------------
# Set 500MHz target, (showing use of a variable)
set INCLK_PERIOD 2.0
create_clock -name clk [get_ports i_clk] -period $INCLK_PERIOD


# -------------------------------------------------------------------------
# Example of defining a generated clock
# -------------------------------------------------------------------------
# create_generated_clock -name clk_gate [ get_pins {i_clkgate/clk_out} ] -source  [get_ports {i_clk} ] -divide_by 1

# -------------------------------------------------------------------------
# Example of setting asynchronous clock groups if more than one clock
# -------------------------------------------------------------------------
# Create a new async clock
# create_clock -name clk_dummy [get_ports i_clk_dummy] -period 1.33

# From example above, the clk_gate is related to clk, 
# but clk_dummy is asynchronous to both
# set_clock_groups -asynchronous -group {clk clk_gate} \
#                                -group {clk_dummy}
