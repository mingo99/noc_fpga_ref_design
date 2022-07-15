#######################################
# ACE GENERATED DELAYS SDC FILE
# Generated on: 2022.01.04 at 10:48:02 PST
# By: ACE 8.6.1
# From project: noc_2d_ref_design_top
#######################################
# IO Ring Boundary Delays SDC File
#######################################
# SDC PVT Conditions:
# Voltage: 850 Temperature: 125 Corner: slow
#######################################
# Boundary pin delays for noc_2d
# Boundary pin delays for pll_chk_clk
# Boundary pin delays for pll_send_clk
# Boundary pin delays for vp_clkio_ne
# Boundary pin delays for vp_clkio_nw
# Boundary pin delays for vp_clkio_se
# Boundary pin delays for vp_clkio_sw
# Boundary pin delays for vp_gpio_n_b0
# Boundary pin delays for vp_gpio_n_b1
# Boundary pin delays for vp_gpio_n_b2
# Boundary pin delays for vp_gpio_s_b0
# Boundary pin delays for vp_gpio_s_b1
set_clock_latency -source -late -rise 0.722933 [get_clocks mcio_vio_45_10_clk]
set_clock_latency -source -early -rise 0.647351 [get_clocks mcio_vio_45_10_clk]
# Boundary pin delays for vp_gpio_s_b2
# Boundary pin delays for vp_pll_nw_2
# Boundary pin delays for vp_pll_sw_2

######################################
# End IO Ring Boundary Delays SDC File
######################################
