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
# Description : ac7t1500 full-chip BFM simulation filelist
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Set whether the DSM DCI interfaces are set to monitor mode only
# In this mode, use the ACE generated port binding file in the testbench
# to make DCI connections to the DSM
# If not enabled, the DSM DCI interfaces will be active and can be
# connected to directly from the testbench
# Please refer to the DSM chapter in the attached user guide for further details

+define+ACX_DSM_INTERFACES_TO_MONITOR_MODE
# ---------------------------------------------------------------------

# DSM defines
-f ../../src/ioring/pcie_ref_design_top_sim_defines.f

# ---------------------------------------------------------------------
# DSM files
# ---------------------------------------------------------------------
# ACE libraries must be defined first as they are referenced
# by the fullchip files that follow
+incdir+$ACE_INSTALL_DIR/libraries/
# $ACE_INSTALL_DIR/libraries/device_models/AC7t1500ES0_simmodels.v
$ACE_INSTALL_DIR/libraries/device_models/AC7t1500ES0_simmodels.sv

# Fullchip include filelist
# This must be placed before the user filelist as it defines
# the binding macros and utilities used by the user testbench.
# $ACX_DEVICE_INSTALL_DIR/sim/ac7t1500_include_bfm.v
$ACX_DEVICE_INSTALL_DIR/sim/ac7t1500_dsm_filelist.v


