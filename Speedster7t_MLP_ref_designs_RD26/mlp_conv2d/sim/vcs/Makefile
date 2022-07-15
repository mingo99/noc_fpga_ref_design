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
# Description : VCS reference design makefile
# ---------------------------------------------------------------------

# Which simulation flow is required
# Options are STANDALONE or FULLCHIP_BFM
FLOW := FULLCHIP_BFM

# Define the top level module
TOP_LEVEL_MODULE := tb_mlp_conv2d

# Define the source filelist
FILELIST := ../../src/filelist_b60.tcl

# Directory log files are written to
LOG_DIR := ./logs

# Parse output log file to check result
CHECK_SIM_RESULT := grep "Test PASSED" $(LOG_DIR)/$(FLOW)_simulation.log || exit 1;

# Location of device simulation files
export ACX_DEVICE_INSTALL_DIR:=$(ACE_INSTALL_DIR)/system/data/AC7t1500ES0

# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# It should only be necessary to edit below here to customize debug options
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
PLI_TAB = $(VERDI_HOME)/share/PLI/VCS/linux64/novas.tab
PLI_A = $(VERDI_HOME)/share/PLI/VCS/linux64/pli.a
FSDB = -fsdb -P $(PLI_TAB) $(PLI_A) $(DEFINE_FSDB)

VCS_OPTIONS := 	+v2k -full64 \
				+warn=all,noLCA_FEATURES_ENABLED,noOBSL_OPT,noOPD,noVPI-CT-NS,noTFIPC   \
				+vcs+lic+wait +notimingcheck +vcs+flush+all                             \
				-Mdir=csrc -lca -sverilog -timescale=1ps/1ps -debug_pp +error+2000 +vpi \
				-LDFLAGS -Wl,--no-as-needed												\
				$(FSDB)                        

VCS_OPTIONS_STANDALONE   := +define+ACX_SIM_STANDALONE_MODE +define+AXI_MEM_CHECK_AXI4_PORT
VCS_OPTIONS_FULLCHIP_BFM := -msg_config=fullchip_bfm_vcs_waiver.cfg
VCS_FILES_FULLCHIP_BFM   := -f system_files_bfm.f \
                            -f $(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_dsm_incdirs.f

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
run : run_compile run_simv 

# ---------------------------------------------------------------------
# Debug flow.
# ---------------------------------------------------------------------
debug : run_compile run_simv_debug 

# ---------------------------------------------------------------------
# Flow specific recipes
# ---------------------------------------------------------------------
create_filelist_STANDALONE:
	tclsh ../../scripts/create_sim_project.tcl sim_filelist.f $(FILELIST) ../../scripts/sim_template.f

create_filelist_FULLCHIP_BFM:
	tclsh ../../scripts/create_sim_project.tcl sim_filelist.f $(FILELIST) ../../scripts/sim_template_bfm.f

run_compile_STANDALONE : make_log_dir check_env
	vcs $(VCS_OPTIONS) $(VCS_OPTIONS_STANDALONE) \
        -f sim_filelist.f -l $(LOG_DIR)/$(FLOW)_compile.log -top $(TOP_LEVEL_MODULE) -o $(VCS_OUTPUT_EXE)

run_compile_FULLCHIP_BFM : make_log_dir check_env
	vcs $(VCS_OPTIONS) $(VCS_OPTIONS_FULLCHIP_BFM) $(VCS_FILES_FULLCHIP_BFM) \
        -f sim_filelist.f  -l $(LOG_DIR)/$(FLOW)_compile.log -top $(TOP_LEVEL_MODULE) -o $(VCS_OUTPUT_EXE)


# ---------------------------------------------------------------------
# Common recipes
# ---------------------------------------------------------------------
run_simv: make_log_dir run_compile
	time $(VCS_OUTPUT_EXE) -l $(LOG_DIR)/$(FLOW)_simulation.log
	$(CHECK_SIM_RESULT)

run_simv_debug : make_log_dir run_compile
	time $(VCS_OUTPUT_EXE) +dontStopOnSimulError=1 -l $(LOG_DIR)/$(FLOW)_simulation.log
	$(CHECK_SIM_RESULT)

open_dve :
	dve -full64 -vpd ./sim_output_pluson.vpd &

open_verdi:
	verdi +v2k -sverilog -f sim_filelist.f -ssf ./sim_output_pluson.fsdb

clean_verdi:
	rm -rf ./verdiLog ./novas.*

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
	rm -rf ./novas* ./sim_output_pluson.fsdb ./verdiLog