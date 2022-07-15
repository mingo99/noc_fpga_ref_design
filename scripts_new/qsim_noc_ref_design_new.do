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
set TOP_LEVEL_MODULE     tb_noc_2d_ref_design

# ---------------------------------------------------------------------
# Define the simulation flow
# ---------------------------------------------------------------------
# Only option is FULLCHIP_BFM
set FLOW                 "FULLCHIP_BFM"

# ---------------------------------------------------------------------
# Define the target device
# ---------------------------------------------------------------------
# 2 devices currently supported; AC7t1500ES0 and AC7t1550
set DEVICE               "AC7t1500ES0"

# ---------------------------------------------------------------------
# Define if debug is required
# When enabled this will not perform optimizations, and will enable full
# debug access
# ---------------------------------------------------------------------
set DEBUG 0

# ---------------------------------------------------------------------
# Tcl test script
# Leave blank if no script
# Tcl scripts are in the demo directory
# ---------------------------------------------------------------------
quietly set TCL_TEST_SCRIPT_DIR  "../../demo/scripts"
quietly set TCL_TEST_SCRIPT      "ac7t1500_2D_NoC_demo.tcl"
quietly set SIM_COMMAND_FILENAME "../ac7t1500_2D_NoC_sim.txt"

# ---------------------------------------------------------------------
# Pointer to ACE installation
# Needed by filelist to pick up library locations
# Normally set by ACE install scripts, but can be overridden here if required
# ---------------------------------------------------------------------
# set ::env(ACE_INSTALL_DIR)/opt/achronix/ace/8.6/Achronix-linux/

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
        set argv "$SIM_FILELIST ../../src/filelist.tcl ../../scripts/sim_template_bfm.f"
    }
    "FULLCHIP_RTL" {
        set argv "$SIM_FILELIST ../../src/filelist.tcl ../../scripts/sim_template_bfm.f"
    }
    "STANDALONE" {
        set argv "$SIM_FILELIST ../../src/filelist.tcl ../../scripts/sim_template.f"
    }
    default { puts "Error : Unrecognised FLOW value of $FLOW"; return -1 }
}
set argc [llength $argv]
source ../../scripts/create_sim_project.tcl

# ---------------------------------------------------------------------
# Generate simulation command file
# ---------------------------------------------------------------------
if { $TCL_TEST_SCRIPT != "" } {
    quietly set BASE_DIR [pwd]
    cd $TCL_TEST_SCRIPT_DIR
    puts "Creating simulation command file $SIM_COMMAND_FILENAME from script $TCL_TEST_SCRIPT"
    #ace -batch -script_file $TCL_TEST_SCRIPT -script_args "-reg_lib_sim_generate 1";
	ace -batch -script_file $TCL_TEST_SCRIPT -script_args \"-reg_lib_sim_generate 1\";
    cd $BASE_DIR
}

# ---------------------------------------------------------------------
# Set environment variables, used by compilation scripts
# ---------------------------------------------------------------------
# Process ACE_INSTALL_DIR if incorrectly set
# Substitute any \ with /
quietly set ACE_INSTALL_DIR_PROC [string map {\\ \/} $::env(ACE_INSTALL_DIR)]

# ---------------------------------------------------------------------
# Set DSM files and variables based on selected device
# ---------------------------------------------------------------------
quietly set ::env(ACX_DEVICE_INSTALL_DIR) $ACE_INSTALL_DIR_PROC/system/data/$DEVICE

switch $DEVICE {
    "AC7t1500ES0"   {
                        quietly set DSM_COMPILE_FILE $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_dsm_incdirs.f
                        quietly set DSM_INCLUDE_FILE $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_dsm_filelist.v
                        quietly set VOPT_OPTIONS_FULLCHIP "+noacc+ac7t1500/fullchip_top."
                    }
    "AC7t1550ES0"      {
                        quietly set DSM_COMPILE_FILE $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1550_dsm_incdirs.f
                        quietly set DSM_INCLUDE_FILE $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1550_dsm_filelist.v
                        quietly set VOPT_OPTIONS_FULLCHIP "+noacc+ac7t1550/fullchip_top."
                    }
    default         {
                        puts "ERROR - Unsupported device $DEVICE selected"
                        return -1
                    }
}

# ---------------------------------------------------------------------
# Set options for compilation and simulation
# ---------------------------------------------------------------------
quietly set LOG_DIR               "./logs"
quietly set WLF_FILENAME          sim_output.wlf

quietly set QUESTA_OPTIONS        "-64 -timescale \"1ps/1ps\" -work work -mfcu"

# quietly set VLOG_OPTIONS          "+incdir+$::env(ACE_INSTALL_DIR)/libraries \
#                                   $::env(ACE_INSTALL_DIR)/libraries/device_models/$DEVICE\_simmodels.sv"
quietly set VLOG_OPTIONS          "+incdir+$ACE_INSTALL_DIR_PROC/libraries \
                                   $ACE_INSTALL_DIR_PROC/libraries/device_models/$DEVICE\_simmodels.sv"
quietly set VSIM_OPTIONS          "-L work -wlf $WLF_FILENAME"
quietly set NOWARN_OPTIONS        "+nowarnTFMPC"
quietly set VSIM_OPTIONS_DEBUG    "-voptargs=\"+acc\""
quietly set VOPT_OPTIONS          "+acc"
quietly set TOP_LEVEL_MODULE_OPT  "$TOP_LEVEL_MODULE\_opt"

# Define vsim and vlog options based on the simulation flow
switch $FLOW {
    "FULLCHIP_BFM" {
        quietly set VLOG_FILES           "-f system_files_bfm.f $DSM_INCLUDE_FILE -f $DSM_COMPILE_FILE"
        quietly append VOPT_OPTIONS      " $VOPT_OPTIONS_FULLCHIP"
    }
    "FULLCHIP_RTL" {
        quietly set VLOG_FILES           "-f system_files_rtl.f $DSM_INCLUDE_FILE -f $DSM_COMPILE_FILE"
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
quietly set vlog_str "vlog $QUESTA_OPTIONS $VLOG_OPTIONS $VLOG_FILES -f $SIM_FILELIST -l $LOG_DIR/$FLOW\_compile.log"
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

