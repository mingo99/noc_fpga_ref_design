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
# Description : ac7t1500 full-chip RTL simulation filelist
# ---------------------------------------------------------------------

# Define GDDR Data Rate
+define+GDDR6_DATA_RATE_16
//+define+GDDR6_DATA_RATE_14
//+define+GDDR6_DATA_RATE_12

# Turn on GDDR RTL
# Enable the desired GDDR memory controllers below
# Any undefined controllers will use their BFM model
//+define+ACX_GDDR6_0_FULL
+define+ACX_GDDR6_1_FULL
//+define+ACX_GDDR6_2_FULL
//+define+ACX_GDDR6_3_FULL
//+define+ACX_GDDR6_4_FULL
//+define+ACX_GDDR6_5_FULL
//+define+ACX_GDDR6_6_FULL
//+define+ACX_GDDR6_7_FULL

# ACE libraries must be defined first as they are referenced
# by the fullchip files that follow
+incdir+$ACE_INSTALL_DIR/libraries/
$ACE_INSTALL_DIR/libraries/device_models/7t_simmodels.v

# Fullchip include filelist
# This must be placed before the user filelist as it defines
# the binding macros and utilities used by the user testbench.
$ACX_DEVICE_INSTALL_DIR/sim/ac7t1500_include_bfm.v


