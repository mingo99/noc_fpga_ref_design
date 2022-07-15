# ---------------------------------------------------------------------
#
# Copyright (c) 2021  Achronix Semiconductor Corp.
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

    set outlist [list]
    set skip_next 0

    # Scan the list.  If a comment is found at the start of a line
    # then that element, and the next, (which is the contents of the line)
    # need to be skipped
    foreach element $inlist {
        if { [string first "#" $element] == 0 } {
            set skip_next 1
            continue
        }
        if { $skip_next } {
            set skip_next 0
            continue
        }

        # Not a comment or the element that follows, so write to output
        lappend outlist $element 
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

# Add library file dependant upon technology
switch [string trim $technology] {
    "AchronixSpeedster22iHD" {add_file -verilog $ACE_INSTALL_DIR/libraries/device_models/22i_synplify.v}
    "AchronixSpeedster16t"   {add_file -verilog $ACE_INSTALL_DIR/libraries/device_models/16t_synplify.v}
    "AchronixSpeedster7t"    {add_file -verilog $ACE_INSTALL_DIR/libraries/device_models/7t_synplify.v}
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

