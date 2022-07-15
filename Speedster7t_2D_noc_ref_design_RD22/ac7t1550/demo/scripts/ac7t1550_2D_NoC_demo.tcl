#!/usr/bin/tclsh
# ---------------------------------------------------------------------
#
# Copyright (c) 2021 Achronix Semiconductor Corp.
# All Rights Reserved.
#
# This Software constitutes an unpublished work and contains
# valuable proprietary information and trade secrets belonging
# to Achronix Semiconductor Corp.
#
# Permission is hereby granted to use this Software including
# without limitation the right to copy, modify, merge or distribute
# copies of the software subject to the following condition:
#
# The above copyright notice and this permission notice shall
# be included in in all copies of the Software.
#
# The Software is provided “as is” without warranty of any kind
# expressed or implied, including  but not limited to the warranties
# of merchantability fitness for a particular purpose and non-infringement.
# In no event shall the copyright holder be liable for any claim,
# damages, or other liability for any damages or other liability,
# whether an action of contract, tort or otherwise, arising from, 
# out of, or in connection with the Software
#
# ---------------------------------------------------------------------
# Ac7t1550 2D NoC demo script
# ---------------------------------------------------------------------

# Source utility functions
source AC7t1500ES0_common_utils.tcl

# Process input arguments
ac7t1550::process_args $argc $argv

# Define command filename for simulation
set OUTPUT_FILENAME "../../sim/ac7t1550_2D_NoC_sim.txt"


# Open the command file.
# File will only be created if not running under ACE
# Pass script name, ($argv0), for header
ac7t1550::open_command_file $OUTPUT_FILENAME $argv0

# When running under ACE, ensure jtag port is open
ac7t1550::open_jtag
 
# ---------------------------------------------------------------------
# Flow starts here
# ---------------------------------------------------------------------

# Enable individual read and write reporting to the console
set quiet_script 0

# Define the location of the reg control block NAP
# This is fixed in the testbench, and the ace_placements.pdc
set ur_row 3
set ur_col 3

# Define the various registers addresses
set NUM_USER_REGS       4;      # Number of registers
set CONTROL_REG_ADDR          [format %X [expr {0 * 4}]]
set STATUS_REG_ADDR           [format %X [expr {1 * 4}]]
set NUM_TRANSACTIONS_REG_ADDR [format %X [expr {2 * 4}]]
set SCRATCH_REG_ADDR          [format %X [expr {($NUM_USER_REGS-1) * 4}]]

# ---------------------------------------------------------------------
# Clear all the user registers
# ---------------------------------------------------------------------
ac7t1550::write_comment_line "Clear user registers"
clear_all_user_regs $ur_col $ur_row $NUM_USER_REGS

# First reset the system
ac7t1550::write_comment_line "Reset the System"
ac7t1550::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 0x0

ac7t1550::wait_ns 100

# Release reset
ac7t1550::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 0x60


# Check our user registers scratch register
# Have to have a delay between reads and writes due to the pipelining
# of the registers. 3x10ns.
ac7t1550::nap_axi_write  "NAP_SPACE" $ur_col $ur_row $SCRATCH_REG_ADDR  12345678
ac7t1550::wait_ns 32
ac7t1550::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $SCRATCH_REG_ADDR  12345678
ac7t1550::nap_axi_write  "NAP_SPACE" $ur_col $ur_row $SCRATCH_REG_ADDR  aa55dead
ac7t1550::wait_ns 32
ac7t1550::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $SCRATCH_REG_ADDR  aa55dead

# Disable read and writes being echoed to the ACE Tcl console
set quiet_script 1

# ---------------------------------------------------------------------
# Read the version registers
# ---------------------------------------------------------------------
ac7t1550::write_comment_line "Read version registers"
read_version_regs $ur_col $ur_row


# ---------------------------------------------------------------------
# Test functions here
# ---------------------------------------------------------------------

# Set number of transactions
ac7t1550::nap_axi_write "NAP_SPACE" $ur_col $ur_row $NUM_TRANSACTIONS_REG_ADDR 0x100
ac7t1550::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $NUM_TRANSACTIONS_REG_ADDR 100

# Trigger start on all generators
ac7t1550::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 0x7f
ac7t1550::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 7f

# Wait for test to run
if { ![ac7t1550::get_reg_lib_sim_generate] } {
    # Running on ACE
    sleep 10
    message "Sleeping for $sleep seconds"
    sleep $sleep
} else {
    # Simulation run 
    ac7t1550::wait_us 50
}

# Check Status - read back expected values
message "Check for ERRORs"
ac7t1550::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $STATUS_REG_ADDR 7

# ---------------------------------------------------------------------
# ---------------------------------------------------------------------

# Unset variables to prevent issues when switching designs
unset NUM_USER_REGS
unset CONTROL_REG_ADDR
unset STATUS_REG_ADDR
unset NUM_TRANSACTIONS_REG_ADDR
unset SCRATCH_REG_ADDR
unset ur_row
unset ur_col

# ---------------------------------------------------------------------
#                 Flow ends here
# ---------------------------------------------------------------------

# Close command file
# File will only exist when not running under ACE
ac7t1550::close_command_file $OUTPUT_FILENAME
