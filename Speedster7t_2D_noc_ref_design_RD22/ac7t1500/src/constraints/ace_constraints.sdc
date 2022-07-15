# -------------------------------------------------------------------------
# ACE timing constaint file
# All clocks, clock relationships, and IO timing constraints should be set
# in this file
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# Example Timing constraints NoC reference design
# -------------------------------------------------------------------------
# Not needed here, using generated clock constraints from I/O Designer Toolkit
# Set 500MHz target
#set INCLK_PERIOD 2.0
#create_clock -name i_chk_clk [get_ports i_chk_clk] -period $INCLK_PERIOD
#create_clock -name i_send_clk [get_ports i_send_clk] -period $INCLK_PERIOD

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
# Example of setting asynchronous clock groups if more than one clock
# -------------------------------------------------------------------------
# Create a new async clock
# create_clock -name clk_dummy [get_ports i_clk_dummy] -period 1.33

# From example above, the clk_gate is related to clk, 
# but clk_dummy is asynchronous to both
# set_clock_groups -asynchronous -group {clk clk_gate} \
#                                -group {clk_dummy}

# Setting asynchronous clock groups for i_send_clk, i_chk_clk, and i_reg_clk
 set_clock_groups -asynchronous -group {i_send_clk} \
                                -group {i_chk_clk}  \
                                -group {i_reg_clk}

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

#set multicycle constraints on the two reset nets that are on the clock network
set_multicycle_path -through [get_nets nap_chk_rstn] -to [get_clocks i_chk_clk] -setup 2
set_multicycle_path -through [get_nets nap_chk_rstn] -to [get_clocks i_chk_clk] -hold 1

set_multicycle_path -through [get_nets nap_send_rstn] -to [get_clocks i_send_clk] -setup 2
set_multicycle_path -through [get_nets nap_send_rstn] -to [get_clocks i_send_clk] -hold 1
