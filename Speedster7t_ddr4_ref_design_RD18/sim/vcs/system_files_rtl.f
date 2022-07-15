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

# Enable the DDR4 memory controller RTL
+define+ACX_DDR4_FULL

# Turn-on below defines for Micron Model
//+define+ACX_USE_MICRON_MODEL
//+define+ACX_DDR4_3200
//+define+DDR4_X8
//+define+DDR4_2G 

# Turn-on below defines for SKHynix Model
//+define+ACX_USE_HYNIX_MODEL
//+define+DDR4_8Gx8
//+define+DDR4_3200AA
//+define+ACX_DDR4_3200

# ACE libraries must be defined first as they are referenced
# by the fullchip files that follow
+incdir+$ACE_INSTALL_DIR/libraries/

# Turn-on below library to enable Micron model and preferred simulation tool
//+incdir+../../src/tb/micron/protected_vcs/
//+incdir+../../src/tb/micron/protected_modelsim/

# Turn-on below library to enable SKHynix model
//+incdir+../../src/tb/skhynix


$ACE_INSTALL_DIR/libraries/device_models/7t_simmodels.v

# Fullchip include filelist
# This must be placed before the user filelist as it defines
# the binding macros and utilities used by the user testbench.
$ACX_DEVICE_INSTALL_DIR/sim/ac7t1500_include_bfm.v

