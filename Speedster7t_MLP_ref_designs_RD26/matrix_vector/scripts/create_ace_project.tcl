# ---------------------------------------------------------------------
#
# Copyright (c) 2019  Achronix Semiconductor Corp.
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
# Script to automatically create an ACE project and run it
# Uses a filelist.tcl file to assemble files
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
    add_project_netlist -project $projectName $netlist
}

# Constraint files do not have variables, so no need for subst
if { [info exists ace_constraints_files] } {
    foreach constraint [strip_comments $ace_constraints_files] {
        add_project_constraints -project $projectName [file join $path_to_constraints $constraint]
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

# Run the flow
# ACE defaults to evaluation flow type
# If strict or normal flow type are required, primarily to produce a bitstream, then this has to be
# configured in an $ace_options_files file.  Note that this $ace_options_files will be stored in the
# constraints file directory.
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

