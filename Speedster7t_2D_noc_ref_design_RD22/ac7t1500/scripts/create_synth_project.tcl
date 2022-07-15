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
        # Trim any leading or trailing spaces
        lappend outlist [string trimright [string trimleft $element]]
    }

    return $outlist
}

# Project name and filelist are passed in
# Project name will be the 5th argument on the line
# File list will be the 6th argument on the line
if { $argc < 10 } {
    puts $argc
    puts "Need at least ten arguments, to include project name, filelist and device details"
    return -1
}

# First four arguments are -product synplify_pro -batch syn_generate.tcl
set projName     [lindex $argv 4]
set filelistName [lindex $argv 5]
set rev          [lindex $argv 6]
set technology   [lindex $argv 7]
set device       [lindex $argv 8]
set speedGrade   [lindex $argv 9]

# Support optional 11th argument of the package
if { $argc > 10 } {
    set device_package [lindex $argv 10]
}


puts "Building synthesis project $projName, using filelist $filelistName"

# Set paths to source code
# These are specific to this particular project and may need changing if this script
# is used elsewhere
# Extract path to filelist
set path_to_filelist    [file dirname $filelistName]
set path_to_rtl         $path_to_filelist/rtl
set path_to_rtl_include $path_to_filelist/include
set path_to_constraints $path_to_filelist/constraints

# Create the project
project -new $projName.prj

# Need ACE installation for libraries
# Check that variable is set
set ACE_INSTALL_DIR $::env(ACE_INSTALL_DIR)
if { $ACE_INSTALL_DIR == "" } {
    puts "ERROR - Must set ACE_INSTALL_DIR environment variable"
    puts "        This variable points to the location of the ace executable file"
    return -1
}

# Set the implementation
impl -add $rev -type fpga

# Add ACE libraries and RTL include path to library list
set_option -include_path "$path_to_rtl_include; $ACE_INSTALL_DIR/libraries/"

# Compute device specific synthesis library files
# Support both .sv and .v files.  The change was in ACE 8.6
set ac7t1500_lib_file   [file join $ACE_INSTALL_DIR/libraries/device_models AC7t1500ES0_synplify.sv]
set ac7t1550_lib_file   [file join $ACE_INSTALL_DIR/libraries/device_models AC7t1550ES0_synplify.sv]
set ac7t1500_lib_file_v [file join $ACE_INSTALL_DIR/libraries/device_models AC7t1500ES0_synplify.v]
set ac7t1550_lib_file_v [file join $ACE_INSTALL_DIR/libraries/device_models AC7t1550_synplify.v]

# Add library file dependant upon technology
switch [string trim $technology] {
    "AchronixSpeedster22iHD" {add_file -verilog $ACE_INSTALL_DIR/libraries/device_models/22i_synplify.v}
    "AchronixSpeedster16t"   {add_file -verilog $ACE_INSTALL_DIR/libraries/device_models/16t_synplify.v}
    "AchronixSpeedster7t"    {  if { [file exists $ac7t1500_lib_file] && ($device == "AC7t1500ES0") } {
                                    add_file -verilog $ac7t1500_lib_file
                                } elseif { [file exists $ac7t1550_lib_file] && ($device == "AC7t1550ES0") } {
                                    add_file -verilog $ac7t1550_lib_file
                                } elseif { [file exists $ac7t1500_lib_file_v] && ($device == "AC7t1500ES0") } {
                                    add_file -verilog $ac7t1550_lib_file_v
                                } elseif { [file exists $ac7t1550_lib_file_v] && ($device == "AC7t1550") } {
                                    add_file -verilog $ac7t1550_lib_file_v
                                } elseif { [file exists $ac7t1550_lib_file] && ($device == "AC7t1550") } {
                                    add_file -verilog $ac7t1550_lib_file
                                } else {
                                    add_file -verilog $ACE_INSTALL_DIR/libraries/device_models/7t_synplify.v
                                }
                             }
    default                  {puts "Error - unknown technology for create_synth_project -$technology-"; return -1}
}

# Read the filelist
if { ![file exists $filelistName] } {
    puts "No such file $filelistName.  Current dir [pwd]"
    return -1
} else {
    source $filelistName
}

# Add include files
if { [info exists rtl_include_files] } {
    foreach fname [strip_comments $rtl_include_files] {
        add_file -verilog [file join $path_to_rtl_include $fname]
    }
}

# Add Verilog source files
if { [info exists rtl_verilog_files] } {
    foreach fname [strip_comments $rtl_verilog_files] {
        if { [file ext $fname] == "sv" } {
            add_file -verilog -vlog_std sysv [file join $path_to_rtl $fname]
        } else {
            add_file -verilog [file join $path_to_rtl $fname]
        }
    }
}

# Add VHDL source files
if { [info exists rtl_vhdl_files] } {
    foreach fname [strip_comments $rtl_vhdl_files] {
        add_file -vhdl -lib work [file join $path_to_rtl $fname]
    }
}

# Add constraint files
if { [info exists synplify_constraints_files] } {
    foreach fname [strip_comments $synplify_constraints_files] {
        add_file -constraint [file join $path_to_constraints $fname]
    }
}

# Set device options
set_option -technology $technology
set_option -part $device
set_option -speed_grade $speedGrade
# Default to Speedcore if no package defined.
if { [info exists device_package] } {
    set_option -package $device_package
} else {
    set_option -package CORE
}

# Default to using the project name as the top level
# May wish to change this in other projects
set_option -top_module $projName


# Add in any particular options for this synthesis run
# Add constraint files
if { [info exists synplify_option_files] } {
    foreach fname $synplify_option_files {
        source [file join $path_to_constraints $fname]
    }
}

# Set output netlist
project -result_file $projName.vm

# Save the project before running.  Then if there are errors during the run,
# the project can be checked, or opened in the GUI
project -save $projName.prj

# Run the project
project -run

