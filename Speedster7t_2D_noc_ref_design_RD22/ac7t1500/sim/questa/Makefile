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
# Description : Questa reference design makefile
# ---------------------------------------------------------------------

# Which simulation flow is required
# Only option for this design is FULLCHIP_BFM
FLOW := FULLCHIP_BFM

# Define the top level module
TOP_LEVEL_MODULE := tb_noc_2d_ref_design

# Define the target device
# 2 devices currently supported; AC7t1500ES0 and AC7t1550ES0
DEVICE     := AC7t1500ES0

# Define the WLF waveform filename
WLF_FILENAME := sim_output.wlf

# Directory log files are written to
LOG_DIR := ./logs

# Parse output log file to check result
CHECK_SIM_RESULT := grep "TEST PASSED" $(LOG_DIR)/$(FLOW)_simulation.log || exit 1;

# Tcl test script
# Leave blank if no script
# Tcl scripts are in the demo directory
TCL_TEST_SCRIPT_DIR  := ../../demo/scripts
TCL_TEST_SCRIPT      := ac7t1500_2D_NoC_demo.tcl
SIM_COMMAND_FILENAME := ../ac7t1500_2D_NoC_sim.txt

# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# It should only be necessary to edit below here to customize debug options
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------

# Location of Device Simulation Model, (DSM), files
ifeq ($(DEVICE),AC7t1500ES0)
    export ACX_DEVICE_INSTALL_DIR  = $(ACE_INSTALL_DIR)/system/data/$(DEVICE)
    DSM_COMPILE_FILE              := $(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_dsm_incdirs.f
    DSM_INCLUDE_FILE              := $(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_dsm_filelist.v
    VOPT_OPTIONS_FULLCHIP         := "+noacc+ac7t1500/fullchip_top."
else ifeq ($(DEVICE),AC7t1550ES0)
    export ACX_DEVICE_INSTALL_DIR  = $(ACE_INSTALL_DIR)/system/data/$(DEVICE)
    DSM_COMPILE_FILE              := $(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1550_dsm_incdirs.f
    DSM_INCLUDE_FILE              := $(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1550_dsm_filelist.v
    VOPT_OPTIONS_FULLCHIP         := "+noacc+ac7t1550/fullchip_top."
else
    $(error Unsupported device $(DEVICE) selected)
endif

# Basic options for all Questa simulations
QUESTA_OPTIONS              := -64 -timescale "1ps/1ps" -work work -mfcu \
                               +incdir+$(ACE_INSTALL_DIR)/libraries/                               

QUESTA_OPTIONS_STANDALONE   := +define+ACX_SIM_STANDALONE_MODE
QUESTA_FILES_FULLCHIP_BFM   := -f system_files_bfm.f $(ACE_INSTALL_DIR)/libraries/device_models/$(DEVICE)_simmodels.sv \
                               $(DSM_INCLUDE_FILE) -f $(DSM_COMPILE_FILE)
QUESTA_FILES_FULLCHIP_RTL   := -f system_files_rtl.f $(ACE_INSTALL_DIR)/libraries/device_models/$(DEVICE)_simmodels.sv \
                               $(DSM_INCLUDE_FILE) -f $(DSM_COMPILE_FILE)

VSIM_OPTIONS          := -L work -wlf $(WLF_FILENAME)
NOWARN_OPTIONS        := +nowarnTFMPC
VSIM_OPTIONS_DEBUG    := -voptargs="+acc"
VOPT_OPTIONS          := "+acc"
TOP_LEVEL_MODULE_OPT  := "$(TOP_LEVEL_MODULE)_opt"

# When optimizing for all flows other than STANDALONE, optimize the target device
# To run simulations without optimizations, invoke "make run_vsim_debug"
# Also When running the GUI simulator, use a different file for STANDALONE mode
ifneq ($(FLOW),STANDALONE)
    $(info Fullchip optimization)
    VOPT_OPTIONS += $(VOPT_OPTIONS_FULLCHIP)
    WAVE_FILE    := wave.do
else
    WAVE_FILE    := wave_standalone.do
endif



# ---------------------------------------------------------------------
# Makefile default
# ---------------------------------------------------------------------
all : run

# ---------------------------------------------------------------------
# Default flow.
# ---------------------------------------------------------------------
run : $(SIM_COMMAND_FILENAME) run_compile run_vsim

# ---------------------------------------------------------------------
# Debug flow.
# ---------------------------------------------------------------------
debug : $(SIM_COMMAND_FILENAME) run_compile run_vsim_debug


# ---------------------------------------------------------------------
# Recipe redirect
# ---------------------------------------------------------------------
run_compile : create_filelist_$(FLOW) run_compile_$(FLOW)
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Flow specific recipes
# ---------------------------------------------------------------------
create_filelist_STANDALONE :
	tclsh ../../scripts/create_sim_project.tcl sim_filelist.f ../../src/filelist.tcl ../../scripts/sim_template.f

create_filelist_FULLCHIP_BFM :
	tclsh ../../scripts/create_sim_project.tcl sim_filelist.f ../../src/filelist.tcl ../../scripts/sim_template_bfm.f

create_filelist_FULLCHIP_RTL :
	tclsh ../../scripts/create_sim_project.tcl sim_filelist.f ../../src/filelist.tcl ../../scripts/sim_template_bfm.f

run_compile_STANDALONE : QUESTA_OPTIONS += $(QUESTA_OPTIONS_STANDALONE)
run_compile_STANDALONE : make_log_dir check_env
	vlog $(QUESTA_OPTIONS) -f sim_filelist.f -l $(LOG_DIR)/$(FLOW)_compile.log

run_compile_FULLCHIP_BFM : make_log_dir check_env
	vlog $(QUESTA_OPTIONS) $(QUESTA_FILES_FULLCHIP_BFM) \
        -f sim_filelist.f  -l $(LOG_DIR)/$(FLOW)_compile.log

run_compile_FULLCHIP_RTL : make_log_dir check_env
	vlog $(QUESTA_OPTIONS) $(QUESTA_FILES_FULLCHIP_RTL) \
        -f sim_filelist.f  -l $(LOG_DIR)/$(FLOW)_compile.log

run_opt : run_compile_$(FLOW)
	vopt $(QUESTA_OPTIONS) $(VOPT_OPTIONS) $(NOWARN_OPTIONS) -l $(LOG_DIR)/$(FLOW)_opt.log \
        $(TOP_LEVEL_MODULE) -o $(TOP_LEVEL_MODULE_OPT)

# ---------------------------------------------------------------------
# Common recipes
# ---------------------------------------------------------------------
$(SIM_COMMAND_FILENAME) : $(TCL_TEST_SCRIPT_DIR)/$(TCL_TEST_SCRIPT)
	cd $(TCL_TEST_SCRIPT_DIR);  \
	ace -batch -script_file $(TCL_TEST_SCRIPT) -script_args "-reg_lib_sim_generate 1";

# Vsim run using optimized database
run_vsim : make_log_dir run_opt
	vsim -c -do "run -all" $(VSIM_OPTIONS) -l $(LOG_DIR)/$(FLOW)_simulation.log work.$(TOP_LEVEL_MODULE_OPT)
	$(CHECK_SIM_RESULT)

# Vsim run, using the GUI with non-optimized database and with debug options enabled.
run_vsim_debug : make_log_dir run_compile
	vsim -gui $(VSIM_OPTIONS) $(VSIM_OPTIONS_DEBUG) $(NOWARN_OPTIONS) -do $(WAVE_FILE) \
         -l $(LOG_DIR)/$(FLOW)_simulation.log work.$(TOP_LEVEL_MODULE) 

open_wave:
	vsim -gui -view $(WLF_FILENAME) -do $(WAVE_FILE) &

make_log_dir:
	mkdir -p $(LOG_DIR)

# The following environment variable must be set
.PHONY : check_env
check_env :
ifndef ACE_INSTALL_DIR
	$(error ACE_INSTALL_DIR is undefined in the environment)
endif

clean:
	rm -rf $(LOG_DIR)
	rm -rf ./work/
	rm -rf ./transcript
	rm -rf ./modelsim.ini
	rm -rf ./sim_filelist.f
	rm -rf ./$(WLF_FILENAME)

