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
quietly set TOP_LEVEL_MODULE     tb_pcie_ref_design

# ---------------------------------------------------------------------
# Define the simulation flow
# ---------------------------------------------------------------------
# Options for the flow are FULLCHIP_BFM and FULLCHIP_RTL
quietly set FLOW                 "FULLCHIP_BFM"

# ---------------------------------------------------------------------
# Define if debug is required
# When enabled this will not perform optimizations, and will enable full
# debug access
# ---------------------------------------------------------------------
quietly set DEBUG 0

# ---------------------------------------------------------------------
# Define if a wave file should be produced
# This will assist debugging, however it will also slow simulation
# ---------------------------------------------------------------------
quietly set WAVE_DUMP YES

# ---------------------------------------------------------------------
# Pointer to ACE installation
# Needed by filelist to pick up library locations
# Normally set by ACE install scripts, but can be overridden here if required
# ---------------------------------------------------------------------
# set ::env(ACE_INSTALL_DIR)/opt/achronix/ace/8.3.3/Achronix-linux/

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
# Set environment variables, used by compilation scripts
# ---------------------------------------------------------------------
# Process ACE_INSTALL_DIR if incorrectly set
# Substitute any \ with /
quietly set ACE_INSTALL_DIR_PROC [string map {\\ \/} $::env(ACE_INSTALL_DIR)]

# quietly set ::env(ACX_DEVICE_INSTALL_DIR) $ACE_INSTALL_DIR_PROC/system/data/yuma-alpha-rev0
quietly set ::env(ACX_DEVICE_INSTALL_DIR) $ACE_INSTALL_DIR_PROC/system/data/AC7t1500ES0

# ---------------------------------------------------------------------
# Check if running FULLCHIP_RTL that DESIGNWARE_HOME and DESIGN_DIR are set
# If set, then define the simulation options that require them.
# In addition compile the PLI functions needed for RTL simulation
# ---------------------------------------------------------------------
if { $FLOW == "FULLCHIP_RTL" } {
    if { ![info exists ::env(DESIGNWARE_HOME)] } {
        echo "DESIGNWARE_HOME must be set in the environment in order to run FULLCHIP_RTL"
        return -1
    }

    if { ![info exists ::env(DESIGN_DIR)] } {
        echo "DESIGN_DIR must be set in the environment in order to run FULLCHIP_RTL"
        return -1
    }

    # Create the vsim options that include the above environment variables
    quietly set VSIM_OPTIONS_RTL  "-voptargs=\"+acc\" -sv_lib $::env(DESIGNWARE_HOME)/vip/common/latest/C/lib/amd64/VipCommonNtb \\
                                   -pli $::env(DESIGN_DIR)/examples/verilog/pcie_svt/tb_pcie_svt_verilog_basic_sys/dyn_mtipli.so \\
                                   -permit_unmatched_virtual_intf +ddr_squashz_to_0 +num_pkts_to_dut=50 +num_pkts_from_dut=50 \\
                                   +num_cr_to_dut=50 +num_cr_from_dut=50 -suppress 8604,12023,8630 \\
                                   +max_pkt_size_to_dut=100 +max_pkt_size_from_dut=100 +root_digest_percentage=50 \\
                                   +link_training_enable=1 +root_supported_speeds=62 +endpoint_supported_speeds=62 \\
                                   +endpoint_link_width=16 +root_link_width=16 \\
                                   +pcie_gen=5 +root_scrambler_enable=1 +endpoint_scrambler_enable=1 +mem64bit_en=1 \\
                                   +msglog_transaction_file=\"gen5transaction.log\""

    # Compile the PLI functions
    set curr_dir $PWD
    cd $(DESIGN_DIR)/examples/verilog/pcie_svt/tb_pcie_svt_verilog_basic_sys
    exec "./run_pcie_svt_verilog_basic_sys -buildonly -w test_basic mtivlog"
    cd $curr_dir
}   

# ---------------------------------------------------------------------
# Set options for compilation and simulation
# ---------------------------------------------------------------------
quietly set LOG_DIR              "./logs"
quietly set WLF_FILENAME         sim_output.wlf

# Note : FULLCHIP_BFM mode has a different timescale than FULLCHIP_RTL
quietly set QUESTA_OPTIONS        "-64 -work work"
quietly set QUESTA_OPTIONS_BFM    "-timescale \"1ps/1ps\""
quietly set QUESTA_OPTIONS_RTL    "-timescale \"1ns/1ps\" -mfcu \\
                                   +warn=all,noLCA_FEATURES_ENABLED,noOBSL_OPT,noOPD,noVPI-CT-NS,noTFIPC \\
                                   +notimingcheck +error+2000 +vpi -suppress 2892 +plusarg_save"

quietly set NOWARN_OPTIONS        "+nowarnTFMPC"

quietly set VSIM_OPTIONS          "-L work -wlf $WLF_FILENAME"
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
        quietly append QUESTA_OPTIONS    " $QUESTA_OPTIONS_BFM"
    }
    "FULLCHIP_RTL" {
        # quietly set VLOG_FILES           "-f system_files_rtl.f -f $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_incdirs_bfm.f"
        quietly set VLOG_FILES           "-f system_files_rtl.f -f $::env(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_dsm_incdirs.f"
        quietly append VOPT_OPTIONS      " $VOPT_OPTIONS_FULLCHIP"
        quietly append VSIM_OPTIONS      " $VSIM_OPTIONS_RTL"
        quietly append QUESTA_OPTIONS    " $QUESTA_OPTIONS_RTL"
    }
    "STANDALONE" {
        quietly set VLOG_FILES           ""
        quietly append QUESTA_OPTIONS    " +define+ACX_SIM_STANDALONE_MODE"
        quietly append QUESTA_OPTIONS    " $QUESTA_OPTIONS_BFM"
    }
    default { puts "Error : Unrecognised FLOW value of $FLOW"; return -1 }
}

if { $WAVE_DUMP == "YES" } {
    quietly append QUESTA_OPTIONS " +define+DUMP_SIM_SIGNALS"
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

