#######################################
# ACE GENERATED DELAYS SDC FILE
# Generated on: 2022.01.10 at 23:19:01 PST
# By: ACE 8.6.1
# From project: noc_2d_ref_design_top
#######################################
# IO Ring Boundary Delays SDC File
#######################################
# SDC PVT Conditions:
# Voltage: 850 Temperature: 0 Corner: slow
#######################################
# Boundary pin delays for noc_2d
# Boundary pin delays for pll_chk_clk
# Boundary pin delays for pll_send_clk
# Boundary pin delays for vp_1550_clkio_ne
# Boundary pin delays for vp_1550_clkio_nw
# Boundary pin delays for vp_1550_clkio_se
# Boundary pin delays for vp_1550_clkio_sw
# Boundary pin delays for vp_1550_gpio_n_b0
# Boundary pin delays for vp_1550_gpio_n_b1
# Boundary pin delays for vp_1550_gpio_n_b2
# Boundary pin delays for vp_1550_gpio_s_b0
# Boundary pin delays for vp_1550_gpio_s_b1
set_clock_latency -source -late -rise 0.74078046 [get_clocks mcio_vio_45_10_clk]
set_clock_latency -source -early -rise 0.66571928 [get_clocks mcio_vio_45_10_clk]
# Boundary pin delays for vp_1550_gpio_s_b2
# Boundary pin delays for vp_1550_pll_nw_2
# Boundary pin delays for vp_1550_pll_sw_2

######################################
# End IO Ring Boundary Delays SDC File
######################################
