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
# Script to automatically create an ACE project and run it
# Uses a filelist.tcl file to assemble files
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


if { [llength $argv] < 6 } {
    puts "Need at least six arguments"
    puts "<projectname> <filelist> <synth revision> <implmentation> <device> <speed>"
    puts "\[-multiprocess <parallel_jobs>\]"
    return -1
}

# Arguments to script passed using -script_args flag
set filename     [lindex $argv 0]
set filelistName [lindex $argv 1]
set rev          [lindex $argv 2]
set impl         [lindex $argv 3]
set device       [lindex $argv 4]
set speedGrade   [lindex $argv 5]
set mp           [lindex $argv 6]
set jobs         [lindex $argv 7]

# Optional argument, may not always be present
# Support 3 options for ioring generation, no, yes, 
# and only, (don't build, generate files, save project and exit)
if { [llength $argv] > 8 } {
    set generate_ioring [string tolower [lindex $argv 8]]
} else {
    set generate_ioring "no"
}

# When called from run_one_ace.sh, if no project, then -force_modern_ui
# becomes the input argument.  Trap against any option argument 
if { [string range $filename 0 0] == "-" } {
    puts "Must provide a correct project name"
    return -1
}

puts "Building project $filename"


set projectName "$filename"
set projectPath "$projectName.acxprj"
set implName    "$impl"

# Relative directory to folders
set path_to_filelist    [file dirname $filelistName]
set path_to_constraints $path_to_filelist/constraints
set path_to_acxip       $path_to_filelist/ace

# Read the filelist
if { ![file exists $filelistName] } {
    puts "No such file $filelistName.  Current dir [pwd]"
    return -1
} else {
    source $filelistName
}

set netlistFiles { "../syn/$rev/$filename.vm" }


# Once the above options are defined, now able to configure the project
# ACE does not have the option to -force generation of a new project
# So if the new project already exists, delete it, any related .lock file
# & the implementation directory
file delete $projectPath
file delete "./ace/$projectName.lock"
file delete -force ./ace/$implName

# Create the new project
create_project $projectPath -impl $implName
set_impl_option -project $projectName -impl $implName  "partname"  $device
set_impl_option -project $projectName -impl $implName  "speed_grade"  $speedGrade

# Need to do subst on the netlists so that the variables get substituted 
# for the correct names
foreach netlist [subst $netlistFiles] {
    # Allow flow to proceed with no netlist file, this supports the ioring_only flow where
    # a netlist may not exist at the time the ioring files are generated
    if { ($generate_ioring != "only") || [file exists $netlist] } { 
        add_project_netlist -project $projectName $netlist
    }
}

# Constraint files do not have variables, so no need for subst
if { [info exists ace_constraints_files] } {
    foreach constraint [strip_comments $ace_constraints_files] {
        # Allow flow to proceed with missing ioring constraints, this supports the a flow where
        # an ioring constraint file may not exist at the time, but they will be generated, and the ioring
        # generation flow then does add_to_project, so this then will add in any missing ioring constraint files.
        if { ($generate_ioring == "no") || [file exists [file join $path_to_constraints $constraint]] } { 
            add_project_constraints -project $projectName [file join $path_to_constraints $constraint]
        }
    }
}

# ACXIP files do not have variables, so no need for subst
if { [info exists multi_acxip_files] } {
    foreach acxip [strip_comments $multi_acxip_files] {
        add_project_ip -project $projectName [file join $path_to_acxip $acxip]
    }
}

# Add in any particular options for this build
# Two similar variables supported
# ACE defaults to evaluation flow type
# If strict or normal flow type are required, primarily to produce a bitstream, then this has to be
# configured in one of these $ace_options_files file.
if { [info exists ace_options_files] } {
    foreach fname [strip_comments $ace_options_files] {
        source [file join $path_to_constraints $fname]
    }
}

if { [info exists ace_impl_option_files] } {
    foreach fname [strip_comments $ace_impl_option_files] {
        source [file join $path_to_constraints $fname]
    }
}

# ------------------------------
# Run the flow
# ------------------------------
if { $generate_ioring != "no" } {
    # ioring generation required.  Save project first
    save_project -no_db

    # The variable $generate_ioring_path indicates where to save the files, (relative to the ACE directory)
    if { ![info exists generate_ioring_path] } {
        puts "\$generate_ioring_path is not defined, defaulting to \"..\/ioring\""
        set generate_ioring_path "../ioring"
    }

    # Make the ioring path relative to the ace directory, (which is where they are included by the filelist).
    # Otherwise the ioring files will be generated within the batch flow directories, 
    # whereas we want them made in the project directories, (src/ioring by default).
    # In this script, the acxip path is the same as the ace directory, so use that variable
    set generate_ioring_path [file join $path_to_acxip $generate_ioring_path]

    # Generate the ioring files, and add any new files to the project
    puts "----------------------------------------------------------------------"
    puts "IOring generation requested; Generating files in $generate_ioring_path"
    puts "----------------------------------------------------------------------"
    generate_ioring_design_files $generate_ioring_path -add_to_project

    # Must ensure that the top level sdc and pdc files are first and second, other files rely on these definitions
    move_project_constraints [file join $generate_ioring_path "$projectName\_ioring.sdc"] 0
    move_project_constraints [file join $generate_ioring_path "$projectName\_ioring.pdc"] 1

    # After generation, new constraint files will be added to the project, so re-save
    save_project -no_db
}

# If we only wanted to generate the ioring files, then exit
if { $generate_ioring == "only" } {
    puts "-----------------------------------------------------------------------------"
    puts "Only IOring generation requested; files generated and project saved.  Exiting"
    puts "-----------------------------------------------------------------------------"
    return 0
}


if { ($mp == "-multiprocess") || ($mp != 0) } {
    # Multiprocess run
    if { ($jobs > 1) && ($jobs < 10) } {
        # As a new project made, need to create the necessary option sets
        run_prepare -create_option_sets
        # GUI saves project having created the options sets.  Gives a base point if multiprocess fails
        save_project -no_db
        # Then run multiprocesses
        run_multiprocess -parallel_job_count $jobs -stop_flow report_timing_routed
    } else {
        puts "Invalid number of parallel jobs specified : $jobs"
    }
} else {
    # Save project before starting run.
    save_project -no_db
    # Standard run
    run
}

