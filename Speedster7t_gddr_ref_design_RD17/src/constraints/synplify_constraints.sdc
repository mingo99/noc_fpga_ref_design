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
create_clock -name i_clk [get_ports i_clk] -period $INCLK_PERIOD
create_clock -name gddr6_1_dc0_clk [get_ports gddr6_1_dc0_clk] -period $INCLK_PERIOD
create_clock -name gddr6_2_dc0_clk [get_ports gddr6_2_dc0_clk] -period $INCLK_PERIOD
create_clock -name gddr6_5_dc0_clk [get_ports gddr6_5_dc0_clk] -period $INCLK_PERIOD
create_clock -name gddr6_6_dc0_clk [get_ports gddr6_6_dc0_clk] -period $INCLK_PERIOD



# -------------------------------------------------------------------------
# Example of defining a generated clock
# -------------------------------------------------------------------------
# create_generated_clock -name clk_gate [ get_pins {i_clkgate/clk_out} ] -source  [get_ports {i_clk} ] -divide_by 1

# -------------------------------------------------------------------------
# Create asynchronous clock groups as more than one clock
# -------------------------------------------------------------------------
set_clock_groups -asynchronous -group {i_clk} \
                               -group {gddr6_1_dc0_clk} \
                               -group {gddr6_2_dc0_clk} \
                               -group {gddr6_5_dc0_clk} \
                               -group {gddr6_6_dc0_clk} 


