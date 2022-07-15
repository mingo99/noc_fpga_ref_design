# -------------------------------------------------------------------------
# ACE timing constaint file
# All clock relationships, and IO timing constraints should be set
# in this file
# Clocks are set in the <design_name>_ioring.sdc file
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# Example of adding new clocks, (in this example through a GPIO pin)
# -------------------------------------------------------------------------
# Set 500MHz target
# set INCLK_PERIOD 2.0
# create_clock -name gpio_clk [get_ports i_gpio_clk] -period $INCLK_PERIOD

# -------------------------------------------------------------------------
# Example of IO timing constraints
# -------------------------------------------------------------------------
# It is recommended that in_clk and out_clk are virtual clocks, based on the
# IO ports of their respective clocks.  This allows for the clock skew 
# into the device fabric.
# set_input_delay  -clock in_clk  -min  2   [get_ports din\[*\]]
# set_input_delay  -clock in_clk  -max  2.8 [get_ports din\[*\]]
# set_output_delay -clock out_clk -min -0.2 [get_ports dout\[*\]]
# set_output_delay -clock out_clk -max -0.6 [get_ports dout\[*\]]

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

# -------------------------------------------------------------------------
# Example of optionally creating clocks based on the build
# -------------------------------------------------------------------------
# Auto detect if snapshot is in the design
# if { [get_ports tck] != "" } { 
#     set use_snapshot 1
# } else {
#     set use_snapshot 0
# }
# if { $use_snapshot==1 } {
#     create_clock -period 100.0 -name tck   [get_ports tck]
#     set_clock_groups -asynchronous -group {tck}
# }

#The following output signals to the pins are status signals, we don't need to constrain them
set_false_path -to [get_cells o_xact_done*]
set_false_path -to [get_cells o_fail*]
#The "gddr_ready" signal is used to start the test logic, we don't have to have all modules start 
#at the same clock, thus the timing of this signals arrival is a dont-care
set_false_path -from [get_cells gddr_ready] -to [get_cells gddr_gen_noc*gddr_ready_nap]
