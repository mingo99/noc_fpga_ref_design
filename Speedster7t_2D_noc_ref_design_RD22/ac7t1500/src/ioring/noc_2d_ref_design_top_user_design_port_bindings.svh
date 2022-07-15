//////////////////////////////////////
// ACE GENERATED VERILOG INCLUDE FILE
// Generated on: 2022.01.04 at 10:47:50 PST
// By: ACE 8.6.1
// From project: noc_2d_ref_design_top
//////////////////////////////////////
// User Design Port Binding Include File
//////////////////////////////////////

//////////////////////////////////////
// User Design Ports
//////////////////////////////////////
    // Ports for noc_2d
    // Ports for pll_chk_clk
`ifdef ACX_CLK_SE_FULL
`ACX_BIND_USER_DESIGN_PORT(i_chk_clk, i_user_06_00_trunk_00[16])
`ACX_BIND_USER_DESIGN_PORT(pll_chk_clk_lock, i_user_12_01_lut_17[0])
`endif
    // Ports for pll_send_clk
`ifdef ACX_CLK_SW_FULL
`ACX_BIND_USER_DESIGN_PORT(i_reg_clk, i_user_06_00_trunk_00[1])
`ACX_BIND_USER_DESIGN_PORT(i_send_clk, i_user_06_00_trunk_00[0])
`ACX_BIND_USER_DESIGN_PORT(pll_send_clk_lock, i_user_00_01_lut_17[0])
`endif
    // Ports for vp_clkio_ne
`ACX_BIND_USER_DESIGN_PORT(fpga_rst_l, i_user_06_09_trunk_00[126])
    // Ports for vp_clkio_nw
    // Ports for vp_clkio_se
    // Ports for vp_clkio_sw
    // Ports for vp_gpio_n_b0
`ifdef ACX_GPIO_N_FULL
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_in[0], i_user_11_09_lut_13[15])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_in[1], i_user_11_09_lut_13[23])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_in[2], i_user_11_09_lut_14[3])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_in[3], i_user_11_09_lut_14[11])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_in[4], i_user_11_09_lut_14[19])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_in[5], i_user_11_09_lut_14[27])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_in[6], i_user_11_09_lut_15[7])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_in[7], i_user_11_09_lut_15[15])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_oe[0], o_user_11_09_lut_12[16])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_oe[1], o_user_11_09_lut_12[17])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_oe[2], o_user_11_09_lut_12[18])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_oe[3], o_user_11_09_lut_12[19])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_oe[4], o_user_11_09_lut_12[20])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_oe[5], o_user_11_09_lut_12[21])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_oe[6], o_user_11_09_lut_12[22])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_oe[7], o_user_11_09_lut_12[23])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_out[0], o_user_11_09_lut_13[12])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_out[1], o_user_11_09_lut_13[20])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_out[2], o_user_11_09_lut_14[0])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_out[3], o_user_11_09_lut_14[8])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_out[4], o_user_11_09_lut_14[16])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_out[5], o_user_11_09_lut_14[24])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_out[6], o_user_11_09_lut_15[4])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_fpga_out[7], o_user_11_09_lut_15[12])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_oe_l, o_user_11_09_lut_12[24])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_oe_l_oe, o_user_11_09_lut_12[14])
`ACX_BIND_USER_DESIGN_PORT(led_oe_l, o_user_11_09_lut_13[4])
`ACX_BIND_USER_DESIGN_PORT(led_oe_l_oe, o_user_11_09_lut_12[15])
`endif
    // Ports for vp_gpio_n_b1
`ifdef ACX_GPIO_N_FULL
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir[0], o_user_11_09_lut_10[6])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir[1], o_user_11_09_lut_10[14])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir[2], o_user_11_09_lut_10[22])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir[3], o_user_11_09_lut_11[2])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir[4], o_user_11_09_lut_11[10])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir[5], o_user_11_09_lut_11[18])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir[6], o_user_11_09_lut_11[26])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir[7], o_user_11_09_lut_12[6])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir_oe[0], o_user_11_09_lut_09[10])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir_oe[1], o_user_11_09_lut_09[11])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir_oe[2], o_user_11_09_lut_09[12])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir_oe[3], o_user_11_09_lut_09[13])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir_oe[4], o_user_11_09_lut_09[14])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir_oe[5], o_user_11_09_lut_09[15])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir_oe[6], o_user_11_09_lut_09[16])
`ACX_BIND_USER_DESIGN_PORT(ext_gpio_dir_oe[7], o_user_11_09_lut_09[17])
`ACX_BIND_USER_DESIGN_PORT(led_l[4], o_user_11_09_lut_09[18])
`ACX_BIND_USER_DESIGN_PORT(led_l[5], o_user_11_09_lut_09[26])
`ACX_BIND_USER_DESIGN_PORT(led_l_oe[4], o_user_11_09_lut_09[8])
`ACX_BIND_USER_DESIGN_PORT(led_l_oe[5], o_user_11_09_lut_09[9])
`endif
    // Ports for vp_gpio_n_b2
`ifdef ACX_GPIO_N_FULL
`ACX_BIND_USER_DESIGN_PORT(led_l[0], o_user_11_09_lut_07[0])
`ACX_BIND_USER_DESIGN_PORT(led_l[1], o_user_11_09_lut_07[8])
`ACX_BIND_USER_DESIGN_PORT(led_l[2], o_user_11_09_lut_07[16])
`ACX_BIND_USER_DESIGN_PORT(led_l[3], o_user_11_09_lut_07[24])
`ACX_BIND_USER_DESIGN_PORT(led_l[6], o_user_11_09_lut_08[4])
`ACX_BIND_USER_DESIGN_PORT(led_l[7], o_user_11_09_lut_08[12])
`ACX_BIND_USER_DESIGN_PORT(led_l_oe[0], o_user_11_09_lut_06[4])
`ACX_BIND_USER_DESIGN_PORT(led_l_oe[1], o_user_11_09_lut_06[5])
`ACX_BIND_USER_DESIGN_PORT(led_l_oe[2], o_user_11_09_lut_06[6])
`ACX_BIND_USER_DESIGN_PORT(led_l_oe[3], o_user_11_09_lut_06[7])
`ACX_BIND_USER_DESIGN_PORT(led_l_oe[6], o_user_11_09_lut_06[8])
`ACX_BIND_USER_DESIGN_PORT(led_l_oe[7], o_user_11_09_lut_06[9])
`endif
    // Ports for vp_gpio_s_b0
`ifdef ACX_GPIO_S_FULL
`ACX_BIND_USER_DESIGN_PORT(fpga_avr_rxd, i_user_10_00_lut_07[7])
`ACX_BIND_USER_DESIGN_PORT(fpga_ftdi_rxd, i_user_10_00_lut_07[23])
`ACX_BIND_USER_DESIGN_PORT(fpga_i2c_mux_gnt, i_user_10_00_lut_06[11])
`ACX_BIND_USER_DESIGN_PORT(irq_to_fpga, i_user_10_00_lut_08[3])
`ACX_BIND_USER_DESIGN_PORT(qsfp_int_fpga_l, i_user_10_00_lut_06[3])
`ACX_BIND_USER_DESIGN_PORT(fpga_avr_txd, o_user_10_00_lut_07[26])
`ACX_BIND_USER_DESIGN_PORT(fpga_avr_txd_oe, o_user_10_00_lut_06[16])
`ACX_BIND_USER_DESIGN_PORT(fpga_ftdi_txd, o_user_10_00_lut_08[14])
`ACX_BIND_USER_DESIGN_PORT(fpga_ftdi_txd_oe, o_user_10_00_lut_06[18])
`ACX_BIND_USER_DESIGN_PORT(fpga_i2c_req_l, o_user_10_00_lut_07[18])
`ACX_BIND_USER_DESIGN_PORT(fpga_i2c_req_l_oe, o_user_10_00_lut_06[15])
`ACX_BIND_USER_DESIGN_PORT(irq_to_avr, o_user_10_00_lut_09[10])
`ACX_BIND_USER_DESIGN_PORT(irq_to_avr_oe, o_user_10_00_lut_06[21])
`ACX_BIND_USER_DESIGN_PORT(test[1], o_user_10_00_lut_06[22])
`ACX_BIND_USER_DESIGN_PORT(test_oe[1], o_user_10_00_lut_06[12])
`endif
    // Ports for vp_gpio_s_b1
`ifdef ACX_GPIO_S_FULL
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_45_10_clk, i_user_10_00_mt_00[1])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_in[0], i_user_10_00_lut_03[14])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_in[1], i_user_10_00_lut_03[22])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_in[2], i_user_10_00_lut_04[2])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_in[3], i_user_10_00_lut_04[10])
`ACX_BIND_USER_DESIGN_PORT(mcio_dir[0], o_user_10_00_lut_05[8])
`ACX_BIND_USER_DESIGN_PORT(mcio_dir[1], o_user_10_00_lut_05[16])
`ACX_BIND_USER_DESIGN_PORT(mcio_dir[2], o_user_10_00_lut_05[24])
`ACX_BIND_USER_DESIGN_PORT(mcio_dir[3], o_user_10_00_lut_06[4])
`ACX_BIND_USER_DESIGN_PORT(mcio_dir_45, o_user_10_00_lut_03[16])
`ACX_BIND_USER_DESIGN_PORT(mcio_dir_45_oe, o_user_10_00_lut_03[6])
`ACX_BIND_USER_DESIGN_PORT(mcio_dir_oe[0], o_user_10_00_lut_03[12])
`ACX_BIND_USER_DESIGN_PORT(mcio_dir_oe[1], o_user_10_00_lut_03[13])
`ACX_BIND_USER_DESIGN_PORT(mcio_dir_oe[2], o_user_10_00_lut_03[14])
`ACX_BIND_USER_DESIGN_PORT(mcio_dir_oe[3], o_user_10_00_lut_03[15])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_oe[0], o_user_10_00_lut_03[8])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_oe[1], o_user_10_00_lut_03[9])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_oe[2], o_user_10_00_lut_03[10])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_oe[3], o_user_10_00_lut_03[11])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_out[0], o_user_10_00_lut_04[4])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_out[1], o_user_10_00_lut_04[12])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_out[2], o_user_10_00_lut_04[20])
`ACX_BIND_USER_DESIGN_PORT(mcio_vio_out[3], o_user_10_00_lut_05[0])
`ACX_BIND_USER_DESIGN_PORT(test[2], o_user_10_00_lut_03[24])
`ACX_BIND_USER_DESIGN_PORT(test_oe[2], o_user_10_00_lut_03[7])
`endif
    // Ports for vp_gpio_s_b2
`ifdef ACX_GPIO_S_FULL
`ACX_BIND_USER_DESIGN_PORT(fpga_sys_scl_in, i_user_10_00_lut_01[21])
`ACX_BIND_USER_DESIGN_PORT(fpga_sys_sda_in, i_user_10_00_lut_02[1])
`ACX_BIND_USER_DESIGN_PORT(mcio_scl_in, i_user_10_00_lut_00[17])
`ACX_BIND_USER_DESIGN_PORT(mcio_sda_in, i_user_10_00_lut_00[25])
`ACX_BIND_USER_DESIGN_PORT(fpga_sys_scl_oe, o_user_10_00_lut_00[6])
`ACX_BIND_USER_DESIGN_PORT(fpga_sys_scl_out, o_user_10_00_lut_02[2])
`ACX_BIND_USER_DESIGN_PORT(fpga_sys_sda_oe, o_user_10_00_lut_00[7])
`ACX_BIND_USER_DESIGN_PORT(fpga_sys_sda_out, o_user_10_00_lut_02[10])
`ACX_BIND_USER_DESIGN_PORT(mcio_oe1_l, o_user_10_00_lut_01[14])
`ACX_BIND_USER_DESIGN_PORT(mcio_oe1_l_oe, o_user_10_00_lut_00[4])
`ACX_BIND_USER_DESIGN_PORT(mcio_oe_45_l, o_user_10_00_lut_01[22])
`ACX_BIND_USER_DESIGN_PORT(mcio_oe_45_l_oe, o_user_10_00_lut_00[5])
`ACX_BIND_USER_DESIGN_PORT(mcio_scl_oe, o_user_10_00_lut_00[2])
`ACX_BIND_USER_DESIGN_PORT(mcio_scl_out, o_user_10_00_lut_00[26])
`ACX_BIND_USER_DESIGN_PORT(mcio_sda_oe, o_user_10_00_lut_00[3])
`ACX_BIND_USER_DESIGN_PORT(mcio_sda_out, o_user_10_00_lut_01[6])
`endif
    // Ports for vp_pll_nw_2
`ifdef ACX_CLK_NW_FULL
`ACX_BIND_USER_DESIGN_PORT(pll_nw_2_ref0_312p5_clk, i_user_06_09_trunk_00[0])
`ACX_BIND_USER_DESIGN_PORT(vp_pll_nw_2_lock, i_user_00_08_lut_17[2])
`endif
    // Ports for vp_pll_sw_2
`ifdef ACX_CLK_SW_FULL
`ACX_BIND_USER_DESIGN_PORT(pll_sw_2_ref1_312p5_clk, i_user_06_00_trunk_00[2])
`ACX_BIND_USER_DESIGN_PORT(vp_pll_sw_2_lock, i_user_00_01_lut_17[2])
`endif

//////////////////////////////////////
// End IO Ring User Design Port Binding Include File
//////////////////////////////////////
