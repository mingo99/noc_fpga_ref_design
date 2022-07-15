# ---------------------------------------------------------------------
#
# Copyright (c) 2021  Achronix Semiconductor Corp.
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
# Options are FULLCHIP_BFM and FULLCHIP_RTL
FLOW := FULLCHIP_BFM

# Enable or disable waveform dumping
WAVE_DUMP := YES

# Define the top level module
# Synopsys stipulate that the PCIe VIP top level testbench is called top.
TOP_LEVEL_MODULE := tb_pcie_ref_design

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

# Base VCS options
VCS_OPTIONS := +v2k -full64 \
               +warn=all,noLCA_FEATURES_ENABLED,noOBSL_OPT,noOPD,noVPI-CT-NS,noTFIPC   \
               +vcs+lic+wait +notimingcheck +vcs+flush+all                             \
               -Mdir=csrc -lca -sverilog +error+2000 +vpi                               

# Base simv options
VCS_RUN_OPTIONS := -sv_lib $(DESIGNWARE_HOME)/vip/common/latest/C/lib/amd64/VipCommonNtb \
                    +ddr_squashz_to_0 +num_pkts_to_dut=50 +num_pkts_from_dut=50 +num_cr_to_dut=50 +num_cr_from_dut=50 \
                    +max_pkt_size_to_dut=100 +max_pkt_size_from_dut=100 +root_digest_percentage=50 +link_training_enable=1 \
                    +root_supported_speeds=62 +endpoint_supported_speeds=62 +endpoint_link_width=16 +root_link_width=16 \
                    +pcie_gen=5 +root_scrambler_enable=1 +endpoint_scrambler_enable=1 +mem64bit_en=1 \
                    +msglog_transaction_file="gen5transaction.log"

# When running RTL sims, increased simulation speed may be obtained by reducing debug options.
VCS_OPTIONS_FULLCHIP_BFM := -msg_config=fullchip_bfm_vcs_waiver.cfg -debug_pp -timescale=1ps/1ps
VCS_OPTIONS_FULLCHIP_RTL := -msg_config=fullchip_rtl_vcs_waiver.cfg +rad -debug_pp -timescale=1ns/1ps \
                            -P $(DESIGN_DIR)/examples/verilog/pcie_svt/tb_pcie_svt_verilog_basic_sys/pli.tab \
                            $(DESIGN_DIR)/examples/verilog/pcie_svt/tb_pcie_svt_verilog_basic_sys/msglog.o \
                            +define+WAVES_DVE +define+WAVES="dve"

VCS_FILES_FULLCHIP_BFM   := -f system_files_bfm.f \
                            -f $(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_incdirs_bfm.f

VCS_FILES_FULLCHIP_RTL   := -f system_files_rtl.f \
                            -f $(ACX_DEVICE_INSTALL_DIR)/sim/ac7t1500_incdirs_bfm.f

VCS_OUTPUT_EXE           := ./vcs.simv

# Add waveform dump to the compile options 
ifeq ($(WAVE_DUMP), YES)
	VCS_OPTIONS += +define+DUMP_SIM_SIGNALS
endif

# ---------------------------------------------------------------------
# Makefile default
# ---------------------------------------------------------------------
all : run

# ---------------------------------------------------------------------
# Recipe redirect
# ---------------------------------------------------------------------
run_compile : create_filelist_$(FLOW) run_compile_$(FLOW)

# ---------------------------------------------------------------------
# Default flow.
# ---------------------------------------------------------------------
run : run_compile run_simv_$(FLOW) 

# ---------------------------------------------------------------------
# Debug flow.
# ---------------------------------------------------------------------
debug : run_compile run_simv_debug_$(FLOW) 

# ---------------------------------------------------------------------
# Flow specific recipes
# ---------------------------------------------------------------------
create_filelist_FULLCHIP_BFM:
	tclsh ../../scripts/create_sim_project.tcl sim_filelist.f ../../src/filelist.tcl ../../scripts/sim_template_bfm.f

create_filelist_FULLCHIP_RTL:
	tclsh ../../scripts/create_sim_project.tcl sim_filelist.f ../../src/filelist.tcl ../../scripts/sim_template_bfm.f

run_compile_FULLCHIP_BFM : make_log_dir check_env
	vcs $(VCS_OPTIONS) $(VCS_OPTIONS_FULLCHIP_BFM) $(VCS_FILES_FULLCHIP_BFM) \
        -f sim_filelist.f  -l $(LOG_DIR)/$(FLOW)_compile.log -top $(TOP_LEVEL_MODULE) -o $(VCS_OUTPUT_EXE)

run_compile_FULLCHIP_RTL : make_log_dir check_env make_pli
	vcs $(VCS_OPTIONS) $(VCS_OPTIONS_FULLCHIP_RTL) $(VCS_FILES_FULLCHIP_RTL) \
        -f sim_filelist.f  -l $(LOG_DIR)/$(FLOW)_compile.log -top $(TOP_LEVEL_MODULE) -o $(VCS_OUTPUT_EXE)


# ---------------------------------------------------------------------
# Common recipes
# ---------------------------------------------------------------------
run_simv_FULLCHIP_BFM: make_log_dir run_compile
	time $(VCS_OUTPUT_EXE) -l $(LOG_DIR)/$(FLOW)_simulation.log
	$(CHECK_SIM_RESULT)

run_simv_FULLCHIP_RTL: make_log_dir run_compile
	time $(VCS_OUTPUT_EXE) $(VCS_RUN_OPTIONS) -l $(LOG_DIR)/$(FLOW)_simulation.log
	$(CHECK_SIM_RESULT)

run_simv_debug_FULLCHIP_BFM : make_log_dir run_compile
	time $(VCS_OUTPUT_EXE) +dontStopOnSimulError=1 -l $(LOG_DIR)/$(FLOW)_simulation.log
	$(CHECK_SIM_RESULT)

run_simv_debug_FULLCHIP_RTL : make_log_dir run_compile
	time $(VCS_OUTPUT_EXE) $(VCS_RUN_OPTIONS) +dontStopOnSimulError=1 -l $(LOG_DIR)/$(FLOW)_simulation.log
	$(CHECK_SIM_RESULT)

open_dve :
	dve -full64 -vpd ./sim_output_pluson.vpd &

make_log_dir :
	mkdir -p $(LOG_DIR)

make_pli :
	cd $(DESIGN_DIR)/examples/verilog/pcie_svt/tb_pcie_svt_verilog_basic_sys; ./run_pcie_svt_verilog_basic_sys -buildonly -w test_basic vcsmxvlog; cd -

# The following environment variable must be set
.PHONY : check_env
check_env :
ifndef ACE_INSTALL_DIR
	$(error ACE_INSTALL_DIR is undefined in the environment)
endif
ifeq ($(FLOW), FULLCHIP_RTL)
ifndef DESIGNWARE_HOME
	$(error DESIGNWARE_HOME is undefined in the environment)
endif
ifndef DESIGN_DIR
	$(error DESIGN_DIR is undefined in the environment)
endif
endif

clean:
	rm -rf $(LOG_DIR)
	rm -rf ./csrc/
	rm -rf $(VCS_OUTPUT_EXE)*
	rm -rf ./DVEfiles/
	rm -rf ./ucli.key
	rm -rf ./sim_output_pluson.vpd
	rm -rf ./top.root*.pcie_svt.xml
	rm -rf ./gen5transaction.log
	rm -rf ./vc_hdrs.h
	rm -rf ./sim_filelist.f

