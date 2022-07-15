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
        # Trim any leading spaces
        lappend outlist [string trimright [string trimleft $element]]
    }

    return $outlist
}

# Procedure to write the start of a filelist
proc write_filelist_header { fo fptr infile_name vhdl } {
    # Add banner
    puts $fo "\n# -----------------------------------------------"
    puts $fo "# Autogenerated simulation filelist"
    puts $fo "# Do not edit this file as it will be overwritten"
    puts $fo "# Generated by $::argv0 on [clock format [clock seconds] -format {%H:%M:%S %a %d %b %y}]"
    puts $fo "# -----------------------------------------------\n"

    # Copy the contents of the template file to the output file
    # Do this line by line, checking for the marker to insert
    # some files after the filelist
    seek $fptr 0
    set end_block 0
    while { ![eof $fptr] && !$end_block} {
        gets $fptr line
        
        # Skip comments
        if { [regexp -- {\#\#.*} $line] } { continue }

        # Break out of loop if command found
        if { ![regexp -- {\# \[insert filelist here\].*} $line] } {
            puts $fo $line
        } else {
            set end_block 1
        }
    }

    # Add banner
    puts $fo "\n# -------------------------------------"
    puts $fo "# Filelist added files from $infile_name"
    puts $fo "# -------------------------------------\n"

}

# Procedure to write the end of the file list
proc write_filelist_tail { fo fptr infile_name } {
    # Write tail
    puts $fo "\n# -------------------------------------"
    puts $fo "# End of user filelist $infile_name"
    puts $fo "# -------------------------------------\n"

    # Read rest of template file
    while { ![eof $fptr] } {
        gets $fptr line
        # Skip comments
        if { [regexp -- {\#\#.*} $line] } { continue }
        # Write line
        puts $fo $line
    }
}

# Project name and filelist are passed in
# Project name will be the 5th argument on the line
# File list will be the 6th argument on the line
# Optional 7th argument for VHDL template
# puts "$argc : $argv"
if { $argc < 3 } {
    puts $argc
    puts "Need at least three arguments, to include output and input filenames and template.  Got $argc"
    return -1
}

# Three arguments minimum needed
set output_filename [lindex $argv 0]
set input_filelist  [lindex $argv 1]
set input_template  [lindex $argv 2]

if { $argc > 3 } {
    set input_template_vhdl  [lindex $argv 3]
    puts "Building simulation filelist $output_filename, using filelist $input_filelist with templates $input_template and $input_template_vhdl"
} else {
    puts "Building simulation filelist $output_filename, using filelist $input_filelist with template $input_template"
}

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

# Read the filelist
if { ![file exists $input_filelist] } {
    puts "No such file $filelistName.  Current dir [pwd]"
    return -1
} else {
    source $input_filelist
}

# Open the output file
set fpo [open $output_filename {WRONLY CREAT TRUNC}]
if { $fpo == 0} {
    puts "Cannot open output file $output_filename"
    return -1
}

# Write the filelist header
write_filelist_header $fpo $fp_template $input_filelist 0

# Verilog only include paths
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
        if { ([file ext $fname] == ".sv") || ([file ext $fname] == ".svp") } {
            puts $fpo "-sv [file join $path_to_rtl $fname]"
        } else {
            puts $fpo "[file join $path_to_rtl $fname]"
        }
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

# Write end of filelist
write_filelist_tail $fpo $fp_template $input_filelist

# Close template file
close $fp_template

# Close the output file
close $fpo

# ---------------------------------------------------------------------
# Check if VHDL filelist is also required
# ---------------------------------------------------------------------
if { [info exists input_template_vhdl] && [info exists rtl_vhdl_files] && ([llength $rtl_vhdl_files] > 0) } {
    set vhdl_required 1
} else {
    set vhdl_required 0
}

if { $vhdl_required } {
    puts "Generate VHDL filelist"

    set fp_template_vhdl [open $input_template_vhdl RDONLY]
    if { $fp_template_vhdl == 0 } {
        puts "Cannot open template file $input_template_vhdl [pwd]"
        return -1
    }

    # Create output file name
    set output_filename_vhdl "[file rootname $output_filename]\_vhdl[file extension $output_filename]"
puts "VHDL file $output_filename_vhdl"
    # Open the output file
    set fpv [open $output_filename_vhdl {WRONLY CREAT TRUNC}]
    if { $fpv == 0} {
        puts "Cannot open output file $output_filename_vhdl"
        return -1
    }

    # Write the filelist header
#    write_filelist_header $fpv $fp_template_vhdl $input_filelist 0

    # Add VHDL source files
    if { [info exists rtl_vhdl_files] } {
        puts $fpv "\n// VHDL source files"
        foreach fname [strip_comments $rtl_vhdl_files] {
            puts $fpv "[file join $path_to_rtl $fname]"
        }
    }

    # Write end of filelist
#    write_filelist_tail $fpv $fp_template_vhdl $input_filelist

    # Close template file
    close $fp_template_vhdl

    # Close the output file
    close $fpv
}

