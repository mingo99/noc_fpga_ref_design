# ---------------------------------------------------------------------
#
# Copyright (c) 2018  Achronix Semiconductor Corp.
# All Rights Reserved.
#
#
# This software constitutes an unpublished work and contains
# valuable proprietary information and trade secrets belonging
# to Achronix Semiconductor Corp.
#
# This software may not be used, copied, distributed or disclosed
# without specific prior written authorization from
# Achronix Semiconductor Corp.
#
# The copyright notice above does not evidence any actual or intended
# publication of such software.
#
# ---------------------------------------------------------------------
# Script to automatically create a synthesis project and run it
# Uses filelist.tcl to set files and parameters
# ---------------------------------------------------------------------

# Procedure to strip comments from filelist fields
# runtest supports comment fields, so need to strip for compatibility
proc strip_comments { inlist } {

    # Treat the input as a string and split into lines based on carriage return
    set inlist_lines [split $inlist "\n"]

    set outlist [list]

    # Scan the list.  If a comment is found at the start of a line
    # then skip that line.  Or if line is empty, also skip
    foreach element $inlist_lines {
        # puts "Element $element length [string length $element]"
        if { [string first "#" $element] == 0 } {
            continue
        }
        if { $element == "" } {
            continue
        }

        # Not a comment or empty line, so write to output
        # Trim any leading spaces
        lappend outlist [string trimleft $element]
    }

    return $outlist
}

# Project name and filelist are passed in
# Project name will be the 5th argument on the line
# File list will be the 6th argument on the line
# puts "$argc : $argv"
if { $argc < 3 } {
    puts $argc
    puts "Need at least three arguments, to include output and input filenames and template.  Got $argc"
    return -1
}

# Three arguments needed
set output_filename [lindex $argv 0]
set input_filelist  [lindex $argv 1]
set input_template  [lindex $argv 2]

puts "Building simulation filelist $output_filename, using filelist $input_filelist with template $input_template"

# Set paths to source code
# These are specific to this particular project and may need changing if this script
# is used elsewhere
# Extract path to filelist
set path_to_filelist    [file dirname $input_filelist]
set path_to_rtl         $path_to_filelist/rtl
set path_to_rtl_include $path_to_filelist/include
set path_to_tb          $path_to_filelist/tb

# Will need ACE installation for libraries.
# Warn if variable not set
# set ACE_INSTALL_DIR $::env(ACE_INSTALL_DIR)
if { ![info exists ::env(ACE_INSTALL_DIR)] } {
    puts "Warning - ACE_INSTALL_DIR environment variable required for simulation"
    puts "          This variable points to the location of the ace executable file"
}

# Open the template file and read in
puts "[pwd]"
set fp_template [open $input_template RDONLY]
if { $fp_template == 0 } {
    puts "Cannot open template file $input_template [pwd]"
    return -1
}

# Read in the contents of the template file
# then close it
# set ofile [read $fp_template]
# close $fp_template

# Open the output file
set fpo [open $output_filename {WRONLY CREAT TRUNC}]
if { $fpo == 0} {
    puts "Cannot open output file $output_filename"
    return -1
}

# Add banner
puts $fpo "\n# -----------------------------------------------"
puts $fpo "# Autogenerated simulation filelist"
puts $fpo "# Do not edit this file as it will be overwritten"
puts $fpo "# Generated by $::argv0 on [clock format [clock seconds] -format {%H:%M:%S %a %d %b %y}]"
puts $fpo "# -----------------------------------------------\n"

# Copy the contents of the template file to the output file
# Do this line by line, checking for the marker to insert
# some files after the filelist
seek $fp_template 0
set end_block 0
while { ![eof $fp_template] && !$end_block} {
    gets $fp_template line
    
    # Skip comments
    if { [regexp -- {\#\#.*} $line] } { continue }

    # Break out of loop if command found
    if { ![regexp -- {\# \[insert filelist here\].*} $line] } {
        puts $fpo $line
    } else {
        set end_block 1
    }
}
# puts $fpo $ofile


# Read the filelist
if { ![file exists $input_filelist] } {
    puts "No such file $filelistName.  Current dir [pwd]"
    return -1
} else {
    source $input_filelist
}

# Add banner
puts $fpo "\n# -------------------------------------"
puts $fpo "# Filelist added files from $input_filelist"
puts $fpo "# -------------------------------------\n"

# Standard directory structure has include directory.  Add as an incdir
puts $fpo "# Verilog design file include directory"
puts $fpo "+incdir+$path_to_rtl_include"
# Also will require path to testbench directory for tb include files
puts $fpo "# Verilog testbench file include directory"
puts $fpo "+incdir+$path_to_tb"

# Add include files
if { [info exists rtl_include_files] } {
    puts $fpo "\n# Include files"
    foreach fname [strip_comments $rtl_include_files] {
	    if { [file ext $fname] == ".svh" } {
            puts $fpo "-sv [file join $path_to_rtl_include $fname]"
	    } else {
            puts $fpo "[file join $path_to_rtl_include $fname]"
        }
    }
}

# Add Verilog source files
if { [info exists rtl_verilog_files] } {
    puts $fpo "\n# Verilog source files"
	foreach fname [strip_comments $rtl_verilog_files] {
	    if { [file ext $fname] == ".sv" } {
            puts $fpo "-sv [file join $path_to_rtl $fname]"
	    } else {
            puts $fpo "[file join $path_to_rtl $fname]"
        }
	}
}

# Add VHDL source files
if { [info exists rtl_vhdl_files] } {
    puts $fpo "\n# VHDL source files"
	foreach fname [strip_comments $rtl_vhdl_files] {
        puts $fpo "[file join $path_to_rtl $fname]"
	}
}

# Add testbench files
if { [info exists tb_verilog_files] } {
    puts $fpo "\n# Verilog testbench files"
	foreach fname [strip_comments $tb_verilog_files] {
	    if { [file ext $fname] == ".sv" } {
            puts $fpo "-sv [file join $path_to_tb $fname]"
	    } else {
            puts $fpo "[file join $path_to_tb $fname]"
        }
	}
}

# Write tail
puts $fpo "\n# -------------------------------------"
puts $fpo "# End of user filelist $input_filelist"
puts $fpo "# -------------------------------------\n"

# Read rest of template file
while { ![eof $fp_template] } {
    gets $fp_template line
    # Skip comments
    if { [regexp -- {\#\#.*} $line] } { continue }
    # Write line
    puts $fpo $line
}

# Close template file
close $fp_template

# Close the output file
close $fpo

