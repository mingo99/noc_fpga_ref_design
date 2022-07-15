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
set TOP_LEVEL_MODULE     tb_ethernet_ref_design

# ---------------------------------------------------------------------
# Define the simulation flow
# ---------------------------------------------------------------------
# Options are STANDALONE or FULLCHIP_BFM
set FLOW                 "FULLCHIP_BFM"

# ---------------------------------------------------------------------
# Pointer to ACE installation
# Needed by filelist to pick up library locations
# Normally set by ACE install scripts, but can be overridden here if required
# ---------------------------------------------------------------------
# set ::env(ACE_INSTALL_DIR)/opt/achronix/ace/8.1.2/Achronix-linux/

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
if { $FLOW=="FULLCHIP_BFM" } {
    set argv "$SIM_FILELIST ../../src/filelist.tcl ../../scripts/sim_template_bfm.f"
} else {
    set argv "$SIM_FILELIST ../../src/filelist.tcl ../../scripts/sim_template.f"
}
set argc [llength $argv]
source ../../scripts/create_sim_project.tcl

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

# Define vsim and vlog options based on the simulation flow
if { $FLOW=="FULLCHIP_BFM" } {
    quietly set VLOG_OPTIONS         ""
    # quietly set VLOG_FILES           "-f system_files_bfm.f -f $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_incdirs_bfm.f"
    quietly set VLOG_FILES           "-f system_files_bfm.f -f $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_dsm_incdirs.f"
    quietly set VSIM_OPTIONS         "-voptargs=\"+acc\" +nowarnTFMPC -L work -wlf $WLF_FILENAME"
    quietly set VSIM_OPTIONS_NODEBUG "-voptargs=\"+noacc+ac7t1500/fullchip_top.\""
} else {
    quietly set VLOG_OPTIONS         "+define+ACX_SIM_STANDALONE_MODE"
    quietly set VLOG_FILES           ""
    quietly set VSIM_OPTIONS         "-voptargs=\"+acc\" +nowarnTFMPC -L work -wlf $WLF_FILENAME"
    quietly set VSIM_OPTIONS_NODEBUG ""
}

# ---------------------------------------------------------------------
# Options set to match those in the Makefile
# ---------------------------------------------------------------------
# Vlog does not work with options passed as variables.  Combine command line into a single string, then evaluate
quietly set vlog_str "vlog  -timescale \"1ps/1ps\" -work work $VLOG_OPTIONS $VLOG_FILES -f $SIM_FILELIST -l $LOG_DIR/$FLOW\_compile.log"
eval $vlog_str

# ---------------------------------------------------------------------
# Open simulation
# ---------------------------------------------------------------------
# Vsim does not work with options passed as variables.  Combine command line into a single string, then evaluate
quietly set vsim_str "vsim $VSIM_OPTIONS $VSIM_OPTIONS_NODEBUG -l $LOG_DIR/$FLOW\_simulation.log work.$TOP_LEVEL_MODULE"
eval $vsim_str

# ---------------------------------------------------------------------
# Open waveform file
# ---------------------------------------------------------------------
do wave.do

# ---------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------
run -all



