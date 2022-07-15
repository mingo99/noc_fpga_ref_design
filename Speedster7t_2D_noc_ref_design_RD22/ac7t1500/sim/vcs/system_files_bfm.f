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
# Description : AC7t1500 full-chip BFM simulation filelist
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

# Enable the RTL for any of the IP blocks, such as GPIO or PLL, here
# For example
# +define+ACX_CLK_NW_FULL


# ---------------------------------------------------------------------

# Add in DSM defines
-f ../../src/ioring/noc_2d_ref_design_top_sim_defines.f

