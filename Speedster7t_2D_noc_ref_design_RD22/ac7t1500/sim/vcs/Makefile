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
# Description : VCS reference design makefile
# ---------------------------------------------------------------------

# Which simulation flow is required
# Only option for this design is FULLCHIP_BFM
FLOW := FULLCHIP_BFM

# Define the top level module
TOP_LEVEL_MODULE := tb_noc_2d_ref_design

# Define the target device
# 2 options supported, AC7t1500ES0 and AC7t1550ES0
DEVICE     := AC7t1500ES0

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
else ifeq ($(DEVICE),AC7t1550ES0)
    export ACX_DEVICE_INSTALL_DIR  = $(ACE_INSTALL_DIR)/system/data/$(DEVICE)
    DSM_COMPILE_FILE              := $(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1550_dsm_incdirs.f
    DSM_INCLUDE_FILE              := $(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1550_dsm_filelist.v
else
    $(error Unsupported device $(DEVICE) selected)
endif


# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# It should only be necessary to edit below here to customize debug options
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------

VCS_OPTIONS              := +v2k -full64 \
                            +warn=all,noLCA_FEATURES_ENABLED,noOBSL_OPT,noOPD,noVPI-CT-NS,noTFIPC   \
                            -licqueue +notimingcheck +vcs+flush+all                                 \
                            -Mdir=csrc -lca -sverilog -timescale=1ps/1ps -debug_pp +error+2000 +vpi \
                            +incdir+$(ACE_INSTALL_DIR)/libraries/      								\
							-LDFLAGS -Wl,--no-as-needed                         

VCS_OPTIONS_STANDALONE   := +define+ACX_SIM_STANDALONE_MODE -debug_pp 
VCS_OPTIONS_FULLCHIP_BFM := -msg_config=fullchip_bfm_vcs_waiver.cfg -debug_pp  
VCS_FILES_FULLCHIP_BFM   := -f system_files_bfm.f $(ACE_INSTALL_DIR)/libraries/device_models/$(DEVICE)_simmodels.sv \
                            $(DSM_INCLUDE_FILE) -f $(DSM_COMPILE_FILE)
VCS_OPTIONS_FULLCHIP_RTL := -msg_config=fullchip_rtl_vcs_waiver.cfg  +rad -debug_pp 
VCS_FILES_FULLCHIP_RTL   := -f system_files_rtl.f $(ACE_INSTALL_DIR)/libraries/device_models/$(DEVICE)_simmodels.sv \
                            $(DSM_INCLUDE_FILE) -f $(DSM_COMPILE_FILE)

VCS_OUTPUT_EXE           := ./vcs.simv

# ---------------------------------------------------------------------
# Makefile default
# ---------------------------------------------------------------------
all : run

# ---------------------------------------------------------------------
# Recipe redirect
# ---------------------------------------------------------------------
run_compile : create_filelist_$(FLOW) run_compile_$(FLOW)
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Default flow.
# ---------------------------------------------------------------------
run : $(SIM_COMMAND_FILENAME) run_compile run_simv 

# ---------------------------------------------------------------------
# Debug flow.
# ---------------------------------------------------------------------
debug : $(SIM_COMMAND_FILENAME) run_compile run_simv_debug 

# ---------------------------------------------------------------------
# Flow specific recipes
# ---------------------------------------------------------------------
create_filelist_STANDALONE:
	tclsh ../../scripts/create_sim_project.tcl sim_filelist.f ../../src/filelist.tcl ../../scripts/sim_template.f

create_filelist_FULLCHIP_BFM:
	tclsh ../../scripts/create_sim_project.tcl sim_filelist.f ../../src/filelist.tcl ../../scripts/sim_template_bfm.f

create_filelist_FULLCHIP_RTL:
	tclsh ../../scripts/create_sim_project.tcl sim_filelist.f ../../src/filelist.tcl ../../scripts/sim_template_bfm.f

run_compile_STANDALONE : make_log_dir check_env
	vcs $(VCS_OPTIONS) $(VCS_OPTIONS_STANDALONE) \
        -f sim_filelist.f -l $(LOG_DIR)/$(FLOW)_compile.log -top $(TOP_LEVEL_MODULE) -o $(VCS_OUTPUT_EXE)

run_compile_FULLCHIP_BFM : make_log_dir check_env
	vcs $(VCS_OPTIONS) $(VCS_OPTIONS_FULLCHIP_BFM) $(VCS_FILES_FULLCHIP_BFM) \
        -f sim_filelist.f -l $(LOG_DIR)/$(FLOW)_compile.log -top $(TOP_LEVEL_MODULE) -o $(VCS_OUTPUT_EXE)

run_compile_FULLCHIP_RTL : make_log_dir check_env
	vcs $(VCS_OPTIONS) $(VCS_OPTIONS_FULLCHIP_RTL) $(VCS_FILES_FULLCHIP_RTL) \
        -f sim_filelist.f -l $(LOG_DIR)/$(FLOW)_compile.log -top $(TOP_LEVEL_MODULE) -o $(VCS_OUTPUT_EXE)

# ---------------------------------------------------------------------
# Common recipes
# ---------------------------------------------------------------------
$(SIM_COMMAND_FILENAME) : $(TCL_TEST_SCRIPT_DIR)/$(TCL_TEST_SCRIPT)
	cd $(TCL_TEST_SCRIPT_DIR);  \
	ace -batch -script_file $(TCL_TEST_SCRIPT) -script_args "-reg_lib_sim_generate 1";

run_simv: make_log_dir run_compile
	time $(VCS_OUTPUT_EXE) -l $(LOG_DIR)/$(FLOW)_simulation.log
	$(CHECK_SIM_RESULT)

run_simv_debug : make_log_dir run_compile
	time $(VCS_OUTPUT_EXE) +dontStopOnSimulError=1 -l $(LOG_DIR)/$(FLOW)_simulation.log
	$(CHECK_SIM_RESULT)

open_dve :
	dve -full64 -vpd ./sim_output_pluson.vpd &

make_log_dir :
	mkdir -p $(LOG_DIR)

# The following environment variable must be set
.PHONY : check_env
check_env :
ifndef ACE_INSTALL_DIR
	$(error ACE_INSTALL_DIR is undefined in the environment)
endif

clean:
	rm -rf $(LOG_DIR)
	rm -rf ./csrc/
	rm -rf $(VCS_OUTPUT_EXE)*
	rm -rf ./DVEfiles/
	rm -rf ./ucli.key
	rm -rf ./sim_output_pluson.vpd
	rm -rf ./sim_filelist.f

