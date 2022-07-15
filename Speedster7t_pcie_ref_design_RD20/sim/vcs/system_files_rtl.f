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
# ---------------------------------------------------------------------
# Description : ac7t1500 full-chip RTL simulation filelist
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Synopsys PCIE VIP defines
# ---------------------------------------------------------------------
# This define must be first for the VIP
+define+SYNOPSYS_SV

+incdir+$DESIGNWARE_HOME/vip/svt/pcie_svt/latest/sverilog/src/vcs
+incdir+$DESIGNWARE_HOME/vip/svt/pcie_svt/latest/sverilog/include
+incdir+$DESIGNWARE_HOME/vip/svt/pcie_svt/latest/verilog/src/vcs
+incdir+$DESIGNWARE_HOME/vip/svt/pcie_svt/latest/verilog/include
+incdir+$DESIGN_DIR/src/sverilog/vcs
+incdir+$DESIGN_DIR/include/sverilog
+incdir+$DESIGN_DIR/src/verilog/vcs
+incdir+$DESIGN_DIR/include/verilog -y $DESIGN_DIR/src/verilog/vcs -y $DESIGN_DIR/src/sverilog/vcs

+define+PCIESVC_INCLUDE_COVERAGE
+define+PCIESVC_FLAT_INCLUDES
+define+PCIESVC_INCLUDE_PA
+define+PCIESVC_MEM_PATH=tb_pcie_ref_design.mem0
+define+EXPERTIO_PCIESVC_GLOBAL_SHADOW_PATH=tb_pcie_ref_design.global_shadow0
+define+SVC_RANDOM_SEED_SCOPE=tb_pcie_ref_design.global_random_seed
+define+EXPERTIO_PCIESVC_INCLUDE_8G
+define+PCIESVC_SERDES
+define+MSGLOG_LEVEL=3
+define+EXPERTIO_PCIESVC_INCLUDE_8G
+define+EXPERTIO_PCIESVC_INCLUDE_16G
+define+SVT_PCIE_ENABLE_LEGACY_GEN5
+define+SVT_PCIE_ENABLE_GEN5

# ---------------------------------------------------------------------
# VIP specific testbench packages
# ---------------------------------------------------------------------
$DESIGN_DIR/src/sverilog/vcs/pciesvc_coverage_pkg.sv
$DESIGN_DIR/src/sverilog/vcs/pciesvc_pa_pkg.sv

# ---------------------------------------------------------------------
# RTL specific testbench files included here
# ---------------------------------------------------------------------
# If there were in filelist.tcl, they would still be included in BFM mode
# This would then require all of the RTL includes to be present
../../src/tb/pciesvc_device_serdes_x16_model_config.sv
../../src/tb/pcie_rtl_testcase.sv

# ---------------------------------------------------------------------
# Set whether the DSM DCI interfaces are set to monitor mode only
# In this mode, use the ACE generated port binding file in the testbench
# to make DCI connections to the DSM
# If not enabled, the DSM DCI interfaces will be active and can be
# connected to directly from the testbench
# Please refer to the DSM chapter in the attached user guide for further details

+define+ACX_DSM_INTERFACES_TO_MONITOR_MODE

# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
# Define PCIE as RTL
# ---------------------------------------------------------------------
+define+ACX_PCIE_0_FULL
+define+ACX_PCIE_1_FULL
+define+ACX_SERDES_FULL
+define+AWAVE_BUMPS_AS_LOGIC
+define+PG_PINS
+define+FAST_SIM

# DSM defines
// -f ../../src/ioring/pcie_ref_design_top_sim_defines.f

# ACE libraries must be defined first as they are referenced
# by the fullchip files that follow
+incdir+$ACE_INSTALL_DIR/libraries/
$ACE_INSTALL_DIR/libraries/device_models/7t_simmodels.v

# Fullchip include filelist
# This must be placed before the user filelist as it defines
# the binding macros and utilities used by the user testbench.
$ACX_DEVICE_INSTALL_DIR/sim/ac7t1500_include_bfm.v

