#######################################
# ACE GENERATED SDC FILE
# Generated on: 2022.01.10 at 23:18:52 PST
# By: ACE 8.6.1
# From project: noc_2d_ref_design_top
#######################################
# IO Ring Boundary SDC File
#######################################

# Boundary clocks for noc_2d

# Boundary clocks for pll_chk_clk
create_clock -period 2.0040080160491622 i_chk_clk
# Frequency = 498.99999999574254 MHz
set_clock_uncertainty -setup 0.020040080160491622 [get_clocks i_chk_clk]


# Boundary clocks for pll_send_clk
create_clock -period 2.0 i_send_clk
# Frequency = 500.0 MHz
set_clock_uncertainty -setup 0.02 [get_clocks i_send_clk]

create_clock -period 5.0 i_cc_clk
# Frequency = 200.0 MHz
set_clock_uncertainty -setup 0.05 [get_clocks i_cc_clk]

create_clock -period 5.0 i_reg_clk
# Frequency = 200.0 MHz
set_clock_uncertainty -setup 0.05 [get_clocks i_reg_clk]


# Boundary clocks for vp_1550_clkio_ne

# Boundary clocks for vp_1550_clkio_nw

# Boundary clocks for vp_1550_clkio_se

# Boundary clocks for vp_1550_clkio_sw

# Boundary clocks for vp_1550_gpio_n_b0

# Boundary clocks for vp_1550_gpio_n_b1

# Boundary clocks for vp_1550_gpio_n_b2

# Boundary clocks for vp_1550_gpio_s_b0

# Boundary clocks for vp_1550_gpio_s_b1
create_clock -period 100.0 mcio_vio_45_10_clk
# Frequency = 10.0 MHz
set_clock_uncertainty -setup 0.1 [get_clocks mcio_vio_45_10_clk]


# Boundary clocks for vp_1550_gpio_s_b2

# Boundary clocks for vp_1550_pll_nw_2
create_clock -period 3.2 pll_nw_2_ref0_312p5_clk
# Frequency = 312.5 MHz
set_clock_uncertainty -setup 0.032 [get_clocks pll_nw_2_ref0_312p5_clk]


# Boundary clocks for vp_1550_pll_sw_2
create_clock -period 3.2 pll_sw_2_ref1_312p5_clk
# Frequency = 312.5 MHz
set_clock_uncertainty -setup 0.032 [get_clocks pll_sw_2_ref1_312p5_clk]


# Virtual clocks for IO Ring IPs
create_clock -name v_acx_sc_GPIO_H_IOB1_GLB_SER_GEN_CLK -period 100.0

######################################
# End IO Ring Boundary SDC File
######################################
