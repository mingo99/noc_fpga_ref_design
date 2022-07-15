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

# ACE libraries must be defined first as they are referenced
# by the fullchip files that follow
+incdir+$ACE_INSTALL_DIR/libraries/
# $ACE_INSTALL_DIR/libraries/device_models/7t_simmodels.v
$ACE_INSTALL_DIR/libraries/device_models/AC7t1500ES0_simmodels.sv

# Fullchip include filelist
# This must be placed before the user filelist as it defines
# the binding macros and utilities used by the user testbench.
# $ACX_DEVICE_INSTALL_DIR/sim/ac7t1500_include_bfm.v
$ACX_DEVICE_INSTALL_DIR/sim/ac7t1500_dsm_filelist.v


