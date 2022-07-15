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
# Ac7t1500 2D NoC demo script
# ---------------------------------------------------------------------

# Source utility functions
source AC7t1500ES0_common_utils.tcl

# Process input arguments
ac7t1500::process_args $argc $argv

# Define command filename for simulation
set OUTPUT_FILENAME "../../sim/ac7t1500_2D_NoC_sim.txt"


# Open the command file.
# File will only be created if not running under ACE
# Pass script name, ($argv0), for header
ac7t1500::open_command_file $OUTPUT_FILENAME $argv0

# When running under ACE, ensure jtag port is open
ac7t1500::open_jtag

# Function to read a data stream checker 
proc read_ds_checker { name ur_col ur_row base_addr } {
    set TOTAL_ADDR [calc_reg_addr_1inc $base_addr 0]
    set MATCH_ADDR [calc_reg_addr_1inc $base_addr 1]
    set FAIL_ADDR  [calc_reg_addr_1inc $base_addr 2]

    set total_pkts [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $TOTAL_ADDR]
    set match_pkts [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $MATCH_ADDR]
    set fail_pkts  [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $FAIL_ADDR]

    puts "-----------------------------------------"
    if { ([expr 0x$total_pkts] != 0) && ($match_pkts == $total_pkts) && ([expr 0x$fail_pkts] == 0) } {
        puts " $name data stream checker PASS"
        set ret_code 0
    } else {
        puts " $name data stream checker FAIL"
        set ret_code -1
    }
    puts "-----------------------------------------"
    puts "Total packets received    : $total_pkts"
    puts "Matching packets received : $match_pkts"
    puts "Failing packets received  : $fail_pkts"
    puts "-----------------------------------------"

    return $ret_code
}

# ---------------------------------------------------------------------
# Flow starts here
# ---------------------------------------------------------------------

# Enable individual read and write reporting to the console
set quiet_script 0

# Define the location of the reg control block NAP
# This is fixed in the testbench, and the ace_placements.pdc
set ur_row 5
set ur_col 5

# Define the various registers addresses
set NUM_USER_REGS       10;      # Number of registers
set CONTROL_REG_ADDR          [format %X [expr {0 * 4}]]
set STATUS_REG_ADDR           [format %X [expr {1 * 4}]]
set NUM_TRANSACTIONS_REG_ADDR [format %X [expr {2 * 4}]]
set SCRATCH_REG_ADDR          [format %X [expr {($NUM_USER_REGS-1) * 4}]]

# ---------------------------------------------------------------------
# Clear all the user registers
# ---------------------------------------------------------------------
ac7t1500::write_comment_line "Clear user registers"
clear_all_user_regs $ur_col $ur_row $NUM_USER_REGS

# ---------------------------------------------------------------------
# Check our user registers scratch register
# ---------------------------------------------------------------------

# Have to have a delay between reads and writes due to the pipelining
# of the registers. 3x10ns.
ac7t1500::nap_axi_write  "NAP_SPACE" $ur_col $ur_row $SCRATCH_REG_ADDR  12345678
ac7t1500::wait_ns 32
ac7t1500::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $SCRATCH_REG_ADDR  12345678
ac7t1500::nap_axi_write  "NAP_SPACE" $ur_col $ur_row $SCRATCH_REG_ADDR  aa55dead
ac7t1500::wait_ns 32
ac7t1500::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $SCRATCH_REG_ADDR  aa55dead

# Disable further read and writes being echoed to the ACE Tcl console
set quiet_script 1

# ---------------------------------------------------------------------
# Read the version registers
# ---------------------------------------------------------------------
ac7t1500::write_comment_line "Read version registers"
read_version_regs $ur_col $ur_row

# ---------------------------------------------------------------------
# Set transactions
# ---------------------------------------------------------------------

puts "Set transactions"
if { ![ac7t1500::get_reg_lib_sim_generate] } {
    # Maximum AXI transactions, (limited by hardware counters), is 8100
    set num_transactions 8100
} else {
    set num_transactions 200
}

# Set number of transactions
ac7t1500::write_comment_line "Write transactions"
ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $NUM_TRANSACTIONS_REG_ADDR [format %x $num_transactions]
ac7t1500::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $NUM_TRANSACTIONS_REG_ADDR [format %x $num_transactions]

# ---------------------------------------------------------------------
# Run test
# ---------------------------------------------------------------------

ac7t1500::write_comment_line "Start sequence"
puts "Start test"
# Release resets
ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 0x60
# Release column and row check
ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 0x78
# Release column and row send
ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 0x7e
# Enable AXI
ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 0x7f

puts "Status at start of test : [ac7t1500::nap_axi_read "NAP_SPACE" $ur_col $ur_row $STATUS_REG_ADDR]"

# Wait for test to run
if { ![ac7t1500::get_reg_lib_sim_generate] } {
    # Running on ACE
    puts "Sleeping for 2 seconds"
    sleep 2

} else {
    # Simulation run 
    ac7t1500::wait_us 50
}

# ---------------------------------------------------------------------
# Check results
# ---------------------------------------------------------------------

puts "Stop test"

# Stop column and row send
# Space them to have different row and column values
# This doesn't stop the traffic, so we do end up with the same values
ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 0x7c
ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 0x78

# Check if there are any errors
set error_count 0
# rx_count_msb_done, xact_done & both PLL locks should all be asserted when test passes
set correct_final_status 02000007

# Confirm after test run that correct status is received
incr error_count [ac7t1500::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $STATUS_REG_ADDR $correct_final_status]
set final_status [ac7t1500::nap_axi_read "NAP_SPACE" $ur_col $ur_row $STATUS_REG_ADDR]
puts "Final status : $final_status"

# The following should only be run on silicon, see comments inline
if { ![ac7t1500::get_reg_lib_sim_generate] } {

    # Reset send.  This stops the traffic. The data stream checkers need the traffic to be
    # stopped in order to measure pass/fail correctly.
    # Do not set in simulation as this reasserts the row and col fail flags and deasserts xact_done
    ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 0x38

    # Read the data stream checkers
    incr error_count [read_ds_checker "Column" $ur_col $ur_row 0xC]
    incr error_count [read_ds_checker "Row"    $ur_col $ur_row 0x18]

    # Sleep, to ensure that all the puts above have been printed.
    sleep 1
    # Only print when running on silicon, otherwise the message -error causes sims to exit with failure when
    # creating the simulation command file
    if { ($final_status == $correct_final_status) && ($error_count == 0)} {
        message -info "Test PASSED"
    } else {
        puts "Error count $error_count"
        message -error "Test FAILED"
    }

    # Clear everything.
    ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR 0x0
}


# ---------------------------------------------------------------------
# ---------------------------------------------------------------------

# Unset variables to prevent issues when switching designs
unset NUM_USER_REGS
unset CONTROL_REG_ADDR
unset STATUS_REG_ADDR
unset NUM_TRANSACTIONS_REG_ADDR
unset SCRATCH_REG_ADDR
unset num_transactions
unset error_count
unset final_status
unset correct_final_status
unset ur_row
unset ur_col

# ---------------------------------------------------------------------
#                 Flow ends here
# ---------------------------------------------------------------------

# Close command file
# File will only exist when not running under ACE
ac7t1500::close_command_file $OUTPUT_FILENAME

