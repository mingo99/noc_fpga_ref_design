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
# Description : Questa reference design makefile
# ---------------------------------------------------------------------

# Which simulation flow is required
# Only options is STANDALONE
FLOW := STANDALONE

# Define the top level module
TOP_LEVEL_MODULE := tb_dot_product_4_8x8

# Define the WLF waveform filename
WLF_FILENAME := sim_output.wlf

# Directory log files are written to
LOG_DIR := ./logs

# Parse output log file to check result
CHECK_SIM_RESULT := grep "TEST PASSED" $(LOG_DIR)/$(FLOW)_simulation.log || exit 1;

# Location of device simulation files
export ACX_DEVICE_INSTALL_DIR:=$(ACE_INSTALL_DIR)/system/data/yuma-alpha-rev0

# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# It should only be necessary to edit below here to customize debug options
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------

QUESTA_OPTIONS              := -64 -timescale "1ps/1ps" -work work

QUESTA_OPTIONS_STANDALONE   := +define+ACX_SIM_STANDALONE_MODE
QUESTA_FILES_FULLCHIP_BFM   := -f system_files_bfm.f \
                               -f $(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_incdirs_bfm.f
QUESTA_FILES_FULLCHIP_RTL   := -f system_files_rtl.f \
                               -f $(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_incdirs_bfm.f

VSIM_OPTIONS          := -L work -wlf $(WLF_FILENAME)
NOWARN_OPTIONS        := +nowarnTFMPC
VSIM_OPTIONS_DEBUG    := -voptargs="+acc"
VOPT_OPTIONS          := "+acc"
VOPT_OPTIONS_FULLCHIP := "+noacc+ac7t1500/fullchip_top."
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
run : run_compile run_vsim

# ---------------------------------------------------------------------
# Debug flow.
# ---------------------------------------------------------------------
debug : run_compile run_vsim_debug


# ---------------------------------------------------------------------
# Recipe redirect
# ---------------------------------------------------------------------
run_compile : create_filelist_$(FLOW) run_compile_$(FLOW)
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Flow specific recipes
# ---------------------------------------------------------------------
create_filelist_STANDALONE :
	tclsh ../../../scripts/create_sim_project.tcl sim_filelist.f ../../src/filelist.tcl ../../../scripts/sim_template.f

create_filelist_FULLCHIP_BFM :
	tclsh ../../../scripts/create_sim_project.tcl sim_filelist.f ../../src/filelist.tcl ../../../scripts/sim_template_bfm.f

create_filelist_FULLCHIP_RTL :
	tclsh ../../../scripts/create_sim_project.tcl sim_filelist.f ../../src/filelist.tcl ../../../scripts/sim_template_bfm.f

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

