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
# Utility functions to use with Tcl script and the device dictionary
# ---------------------------------------------------------------------
# These functions do not have a namespace as they can be called from multiple
# other scripts or functions


#------------------------------------------------------------------------------------
# Check PLL register status in all corners
#------------------------------------------------------------------------------------
  
proc check_pll_status {} {
    foreach corner [list N S] {
        foreach num [list 0 1 2 3] {
            set x [ac7t1500::noc_read [ac7t1500::csr_named_addr CSR_SPACE CLK_${corner}W BASE_IP SYNTH${num}_STATUS]]
            puts -nonewline "PLL at CLK_${corner}W #$num : $x                         "

            set x [ac7t1500::noc_read [ac7t1500::csr_named_addr CSR_SPACE CLK_${corner}E BASE_IP SYNTH${num}_STATUS]]
            puts "PLL at CLK_${corner}E #$num : $x"

        }

        puts -nonewline "PLL at ENOC_${corner}W  : "
        set x [ac7t1500::noc_read [ac7t1500::csr_named_addr CSR_SPACE ENOC_${corner}W BASE_IP CLK_RST_TOP_CSR_INTERNAL_CSR_STATUS]]
        puts "$x"
        puts ""
    }
    foreach g6 [list 0 1 2 3 4 5 6 7] {
        puts -nonewline "PLL at GDDR_${g6}   : "
        set x [ac7t1500::noc_read [ac7t1500::csr_named_addr CSR_SPACE GDDR_${g6} PHY CPHY_CM_CACM_PHYCMN_PYINITSTS0]]
        puts "$x"
    }
}

#------------------------------------------------------------------------------------
# Read register control block registers and display
# User has to supply the NAP location of the register block
#------------------------------------------------------------------------------------
proc read_version_regs { col row } {

    ac7t1500::write_comment_line "Read version registers"
    set major_ver [ac7t1500::nap_axi_read "NAP_SPACE" $col $row fff0000]
    set minor_ver [ac7t1500::nap_axi_read "NAP_SPACE" $col $row fff0004]
    set patch_ver [ac7t1500::nap_axi_read "NAP_SPACE" $col $row fff0008]
    set p4_ver    [ac7t1500::nap_axi_read "NAP_SPACE" $col $row fff000c]

    scan $major_ver %x major_ver_dec
    scan $minor_ver %x minor_ver_dec
    scan $patch_ver %x patch_ver_dec
    scan $p4_ver    %x p4_ver_dec

    if { ![ac7t1500::get_reg_lib_sim_generate] } {
        puts "-----------------------------------------"
        puts "  Read Version Registers"
        puts "-----------------------------------------"
        puts "  Major Version    : $major_ver_dec"
        puts "  Minor Version    : $minor_ver_dec"
        puts "  Patch Version    : $patch_ver_dec"
        puts "  Perforce Version : $p4_ver_dec"
        puts "-----------------------------------------"
    }

    return [list $major_ver_dec $minor_ver_dec $patch_ver_dec $p4_ver_dec]
}

#------------------------------------------------------------------------------------
# Read Clock monitor when connected to user registers and display frequency
# If reference clock is not provided, default is assumed to be 100MHz
#------------------------------------------------------------------------------------
proc read_clock_monitor { col row addr_offset {ref_clock 100} {quiet 0} } {
    set mon_val [ac7t1500::nap_axi_read "NAP_SPACE" $col $row [ac7t1500::tidy_value $addr_offset 7]]

    # Calculate the target clock frequency.
    # The result from the read will be in hex
    scan $mon_val %x mon_val_dec

    # Calculate value
    set measured_f [expr { round(($mon_val_dec * $ref_clock)/10000) }] 

    if { [namespace exists ::jtag] && ($quiet != 1) } {
        puts "Clock Monitor Block at $addr_offset returns a value of $mon_val_dec"
        puts "With a reference frequency of $ref_clock MHz this equates to $measured_f MHz"
    }

    return $measured_f
}


# ---------------------------------------------------------------------
# Compare values from simulation file with those programmed in hardware
# ---------------------------------------------------------------------
# This will only compare CSR values, anything outside the CSR memory space
# will be ignored.  The ignore will be reported as a warning to the console
# By default this will only be run under ACE, the user can override this if
# they wish to also run in simulation
proc verify_programmed_values { infile {run_in_sim 0}} {

    if { [namespace exists ::jtag] || ($run_in_sim == 1) } {

        set fpi [open $infile {RDONLY}]
        if { $fpi == 0} {
            puts "Cannot open input file $infile"
            return -1
        }

        # Reading the file backwards is slow and costly
        # Read first and get a list of pointers to the start of each line
        # Construct the list of indices
        set indices {}
        while {![eof $fpi]} {
            lappend indices [tell $fpi]
            gets $fpi
        }

        set addr_chkd [list]

        # The config files have the same register written multiple times
        # Need to read from the bottom up, and ignore reading any address that has
        # already been read.
        # Iterate backwards
        foreach idx [lreverse $indices] {
            seek $fpi $idx
            set line [gets $fpi]

            # Ignore blank and comment lines
            if { ([string length $line] < 5) || ([string range $line 0 0] == "#") || \
                 ([string range $line 0 1] == "//") } { continue }

            # Parse input
            if { [info exists full]  } { unset full  }
            if { [info exists addr]  } { unset addr  }
            if { [info exists value] } { unset value }
            regexp {\s*([wrvd])\s+([0-9a-fA-F\_]+)\s+([0-9a-fA-F\_]+)} $line full cmd addr value
            if { ![info exists full] } {
                puts "ERROR - Unable to parse $line"
                return -1
            }
            # puts "$full - $cmd - $addr - $value"

            if { [lsearch $addr_chkd $addr] == -1 } {
                # Get the correct CSR address.  If not a CSR address, then drop entry
                set reg_list [ac7t1500::disassemble_csr_addr $addr]
                if { [llength $reg_list] != 4 } {
                    puts "Warning : Address $addr not decoded to CSR space.  Not verified" 
                    continue
                }

                # Do verify. This will print errors to the console if the verify fails
                # puts "ac7t1500::csr_verify_named $reg_list $value"
                # ac7t1500::csr_verify_named $reg_list $value
                if  { [ac7t1500::csr_verify_named [lindex $reg_list 0] [lindex $reg_list 1] [lindex $reg_list 2] [lindex $reg_list 3] $value] == 0 } {
                    # puts "ac7t1500::csr_verify_named $reg_list $value PASSED"
                }

                # Add addr into the current list as already having been checked
                lappend addr_chkd $addr
            } else {
                # puts "$addr already in the list"
            }

        }

    } else {
        puts "Warning : verify_programmed_values not run"
    }
}

# ---------------------------------------------------------------------
# Calculate an address given a base and offset when the registers offsets
# are given in steps of 1.
# To input hex values, precede the input strings with 0x
# Returns a hex string
# ---------------------------------------------------------------------
proc calc_reg_addr_1inc {base reg_offset} {

    # ACE Tcl console only supports 32-bit ints
    # Various experiments with wide() etc do not work because whenever the
    # value is then passed through scan/format/binary scan etc they only 
    # support a 32-bit input
    # Solution to do as strings

    # Base value will be a hex string anyway, expand to 11 chars
    set base_str [ac7t1500::tidy_value $base 11]

    # Offset can only be to a maximum of 24 bits
    set offset_str [format %06X [expr {($reg_offset*4) + "0x[string range $base_str 5 10]"}]]

    # Join top of base with offset
    set out_str "[string range $base_str 0 4]$offset_str"
    # puts "$base_str $offset_str $out_str"

    return $out_str
}

# ---------------------------------------------------------------------
# Clear all the user registers
# ---------------------------------------------------------------------
proc clear_all_user_regs { ur_col ur_row num_regs } {

    ac7t1500::write_comment_line "Clear all user registers"
    for {set reg 0} {$reg < $num_regs} {incr reg} {
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row [calc_reg_addr_1inc 0x0 $reg] 0x0
    }
}

# ---------------------------------------------------------------------
# Read AXI performance monitor
# ---------------------------------------------------------------------
proc read_axi_monitor { name ur_col ur_row base_addr } {
    # set READ_BW_ADDR    [calc_reg_addr_1inc $base_addr 0]
    # set WRITE_BW_ADDR   [calc_reg_addr_1inc $base_addr 1]
    set CURR_LAT_ADDR   [calc_reg_addr_1inc $base_addr 2]
    set AVG_LAT_ADDR    [calc_reg_addr_1inc $base_addr 3]
    set MAX_LAT_ADDR    [calc_reg_addr_1inc $base_addr 4]
    set MIN_LAT_ADDR    [calc_reg_addr_1inc $base_addr 5]
    set FREQ_WIDTH_ADDR [calc_reg_addr_1inc $base_addr 6]

    puts "-----------------------------------------"
    puts "$name monitor results"
    puts "-----------------------------------------"
    puts "   Bandwidth"
    puts "-----------------------------------------"

    # Read Frequency, width and monitor type
    set freq_width_reg [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $FREQ_WIDTH_ADDR 01000100]

    # puts "freq_width_reg $freq_width_reg"
    set mon_type [string range $freq_width_reg 0 0]
    set freq     [string range $freq_width_reg 1 3]
    set width    [string range $freq_width_reg 4 7]

    if { $mon_type != 0 } { puts "Incorrect monitor type read.  Monitor reports type $mon_type" }

    # puts "Frequency [expr 0x$freq]. Data width [expr 0x$width]"

    # Read the two bandwidth results
    for {set ch 0} {$ch < 2} {incr ch} {
        set BW_ADDR [calc_reg_addr_1inc $base_addr $ch]
        set bw_reg [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $BW_ADDR]

        # Split bandwidth registers
        # [29:20] = Average
        # [19:10] = Max
        # [9:0]   = Min
        set bw_reg_dec [expr 0x$bw_reg]
        set av_bw  [expr { ($bw_reg_dec & 0x3ff00000) >> 20 }]
        set max_bw [expr { ($bw_reg_dec & 0x000ffc00) >> 10 }]
        set min_bw [expr { ($bw_reg_dec & 0x000003ff) }]

        # puts "BW reg $bw_reg"
        # puts "Av hex [format %x $av_bw] Max [format %x $max_bw] Min [format %x $min_bw]"
        # puts "Av $av_bw Max $max_bw Min $min_bw"
        set max_limit [expr (0x$freq * 0x$width)]
        # puts "max_limit $max_limit"

        if {$ch == 0} { set str "read " } else { set str "write" }

        # Results are divided by 1024 as they are accumulated over a 2^10 deep FIFO
        puts "Maximum $str bandwidth : [expr {($max_limit * $max_bw) / (1024.0 * 1000.0)}] Gbps"
        puts "Average $str bandwidth : [expr {($max_limit * $av_bw)  / (1024.0 * 1000.0)}] Gbps"
        puts "Minimum $str bandwidth : [expr {($max_limit * $min_bw) / (1024.0 * 1000.0)}] Gbps"
    }

    puts "-----------------------------------------"
    puts "   Latency"
    puts "-----------------------------------------"

    # Read the latency registers
    # Skip current latency, that would be better served on its own
    for {set ch 3} {$ch < 6} {incr ch} {
        set LAT_ADDR [calc_reg_addr_1inc $base_addr $ch]
        set lat_reg [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $LAT_ADDR]

        # puts "lat_reg $lat_reg"

        # Split bandwidth registers
        # [27:16] = Read
        # [11:0]  = Write
        set lat_reg_dec [expr 0x$lat_reg]
        set rd_lat [expr { ($lat_reg_dec & 0x0fff0000) >> 16 }]
        set wr_lat [expr { ($lat_reg_dec & 0x00000fff) }]

        # puts "rd_lat $rd_lat. wr_lat $wr_lat"

        # Clock frequency period in ns
        set period [expr (1000.0 / 0x$freq)]
        # puts "period $period"

        switch $ch {
            3 { set str "Average" }
            4 { set str "Maximum" }
            5 { set str "Minimum" }
        }

        # Results are divided by 1024 as they are accumulated over a 2^10 deep FIFO
        puts "$str read latency  : [expr {$rd_lat * $period}] ns"
        puts "$str write latency : [expr {$wr_lat * $period}] ns"
    }


    puts "-----------------------------------------"
}

# ---------------------------------------------------------------------
# ---------------------------------------------------------------------

