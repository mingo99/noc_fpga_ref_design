# ---------------------------------------------------------------------
#
# Copyright (c) 2020  Achronix Semiconductor Corp.
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
#
# ---------------------------------------------------------------------
# Description : Questa batch file to simulate a reference design
#               using the Vsim console
#               This supports an OS independent simulation environment
#               1. Open vsim in gui mode, $ vsim -gui
#               2. At the vsim prompt execute the following
#                  QuestaSim> do <this_file_name>.do
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Define top level module
# ---------------------------------------------------------------------
set TOP_LEVEL_MODULE     tb_dot_product_8_8x8

# ---------------------------------------------------------------------
# Define the simulation flow
# ---------------------------------------------------------------------
# Only options is STANDALONE
set FLOW                 "STANDALONE"

# ---------------------------------------------------------------------
# Define if debug is required
# When enabled this will not perform optimizations, and will enable full
# debug access
# ---------------------------------------------------------------------
set DEBUG 0

# ---------------------------------------------------------------------
# Pointer to ACE installation
# Needed by filelist to pick up library locations
# Normally set by ACE install scripts, but can be overridden here if required
# ---------------------------------------------------------------------
# set ::env(ACE_INSTALL_DIR)/opt/achronix/ace/8.2.1.beta/Achronix-linux/

# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
# Should not need to edit below here
# ---------------------------------------------------------------------
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Remove any existing build directory and create fresh
# ---------------------------------------------------------------------
# Use Tcl file command to remove directory
file delete -force work

# Create new library directory
vlib work
vmap work work

# Make log file directory
if { ![file exists logs] } { file mkdir logs }

# ---------------------------------------------------------------------
# Build simulation filelist, from filelist.tcl using script
# ---------------------------------------------------------------------
set SIM_FILELIST "sim_filelist.f"

# Build the sim filelist, using the appropriate template
switch $FLOW {
    "FULLCHIP_BFM" {
        set argv "$SIM_FILELIST ../../src/filelist.tcl ../../../scripts/sim_template_bfm.f"
    }
    "FULLCHIP_RTL" {
        set argv "$SIM_FILELIST ../../src/filelist.tcl ../../../scripts/sim_template_bfm.f"
    }
    "STANDALONE" {
        set argv "$SIM_FILELIST ../../src/filelist.tcl ../../../scripts/sim_template.f"
    }
    default { puts "Error : Unrecognised FLOW value of $FLOW"; return -1 }
}
set argc [llength $argv]
source ../../../scripts/create_sim_project.tcl

# ---------------------------------------------------------------------
# Set environment variables, used by compilation scripts
# ---------------------------------------------------------------------
# Process ACE_INSTALL_DIR if incorrectly set
# Substitute any \ with /
quietly set ACE_INSTALL_DIR_PROC [string map {\\ \/} $::env(ACE_INSTALL_DIR)]

# quietly set ::env(ACX_DEVICE_INSTALL_DIR) $ACE_INSTALL_DIR_PROC/system/data/yuma-alpha-rev0
quietly set ::env(ACX_DEVICE_INSTALL_DIR) $ACE_INSTALL_DIR_PROC/system/data/AC7t1500ES0

# ---------------------------------------------------------------------
# Set options for compilation and simulation
# ---------------------------------------------------------------------
quietly set LOG_DIR              "./logs"
quietly set WLF_FILENAME         sim_output.wlf

quietly set QUESTA_OPTIONS        "-64 -timescale \"1ps/1ps\" -work work"
quietly set VSIM_OPTIONS          "-L work -wlf $WLF_FILENAME"
quietly set NOWARN_OPTIONS        "+nowarnTFMPC"
quietly set VSIM_OPTIONS_DEBUG    "-voptargs=\"+acc\""
quietly set VOPT_OPTIONS          "+acc"
quietly set VOPT_OPTIONS_FULLCHIP "+noacc+ac7t1500/fullchip_top."
quietly set TOP_LEVEL_MODULE_OPT  "$TOP_LEVEL_MODULE\_opt"

# Define vsim and vlog options based on the simulation flow
switch $FLOW {
    "FULLCHIP_BFM" {
        # quietly set VLOG_FILES           "-f system_files_bfm.f -f $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_incdirs_bfm.f"
        quietly set VLOG_FILES           "-f system_files_bfm.f -f $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_dsm_incdirs.f"
        quietly append VOPT_OPTIONS      " $VOPT_OPTIONS_FULLCHIP"
    }
    "FULLCHIP_RTL" {
        # quietly set VLOG_FILES           "-f system_files_rtl.f -f $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_incdirs_bfm.f"
        quietly set VLOG_FILES           "-f system_files_rtl.f -f $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_dsm_incdirs.f"
        quietly append VOPT_OPTIONS      " $VOPT_OPTIONS_FULLCHIP"
    }
    "STANDALONE" {
        quietly set VLOG_FILES           ""
        quietly append QUESTA_OPTIONS    " +define+ACX_SIM_STANDALONE_MODE"
    }
    default { puts "Error : Unrecognised FLOW value of $FLOW"; return -1 }
}


# ---------------------------------------------------------------------
# Compile code
# ---------------------------------------------------------------------
# Vlog does not work with options passed as variables.  Combine command line into a single string, then evaluate
quietly set vlog_str "vlog $QUESTA_OPTIONS $VLOG_FILES -f $SIM_FILELIST -l $LOG_DIR/$FLOW\_compile.log"
eval $vlog_str


# ---------------------------------------------------------------------
# Optionally optimize, then construct simulation command
# ---------------------------------------------------------------------
if { $DEBUG == 0 } {
    # Optimize
    quietly set vopt_str "vopt $QUESTA_OPTIONS $VOPT_OPTIONS $NOWARN_OPTIONS -l $LOG_DIR/$FLOW\_opt.log \
                              $TOP_LEVEL_MODULE -o $TOP_LEVEL_MODULE_OPT"
    eval $vopt_str

    # Simulation command
    quietly set vsim_str "vsim $VSIM_OPTIONS -l $LOG_DIR/$FLOW\_simulation.log work.$TOP_LEVEL_MODULE_OPT"
} else {
    # Simulation command
    quietly set vsim_str "vsim $VSIM_OPTIONS $NOWARN_OPTIONS $VSIM_OPTIONS_DEBUG -l $LOG_DIR/$FLOW\_simulation.log work.$TOP_LEVEL_MODULE"
}

# ---------------------------------------------------------------------
# Simulate
# ---------------------------------------------------------------------
eval $vsim_str

# ---------------------------------------------------------------------
# Open waveform file
# ---------------------------------------------------------------------
if { $FLOW == "STANDALONE" } {
    do wave_standalone.do
} else {
    do wave.do
}

# ---------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------
run -all

