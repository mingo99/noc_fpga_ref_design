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
# Set NAP clock to 500MHz
set NAP_CLK_PERIOD 2.0
create_clock -name i_clk          [get_ports i_clk]          -period $NAP_CLK_PERIOD
# Set DCI clock to 400MHz, (maximum supported rate)
set DCI_CLK_PERIOD 2.5
create_clock -name ddr4_1_clk     [get_ports ddr4_1_clk]     -period $DCI_CLK_PERIOD
# Training clock is set to 250MHz.
create_clock -name i_training_clk [get_ports i_training_clk] -period 4.0

# -------------------------------------------------------------------------
# Example of defining a generated clock
# -------------------------------------------------------------------------
# create_generated_clock -name clk_gate [ get_pins {i_clkgate/clk_out} ] -source  [get_ports {i_clk} ] -divide_by 1

# -------------------------------------------------------------------------
# Set asynchronous clock groups as more than one clock
# -------------------------------------------------------------------------
set_clock_groups -asynchronous -group {i_clk} \
                               -group {ddr4_1_clk} \
							   -group {i_training_clk}
