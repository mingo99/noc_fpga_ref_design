//////////////////////////////////////
// ACE GENERATED VERILOG INCLUDE FILE
// Generated on: 2022.01.10 at 23:18:52 PST
// By: ACE 8.6.1
// From project: noc_2d_ref_design_top
//////////////////////////////////////
// User Design Signal List Include File
//////////////////////////////////////

    // Ports for noc_2d
    // Ports for pll_chk_clk
    logic        i_chk_clk;
    logic        pll_chk_clk_lock;
    // Ports for pll_send_clk
    logic        i_cc_clk;
    logic        i_reg_clk;
    logic        i_send_clk;
    logic        pll_send_clk_lock;
    // Ports for vp_1550_clkio_ne
    logic        fpga_rst_l;
    // Ports for vp_1550_clkio_nw
    // Ports for vp_1550_clkio_se
    // Ports for vp_1550_clkio_sw
    // Ports for vp_1550_gpio_n_b0
    logic        ext_gpio_fpga_in[0];
    logic        ext_gpio_fpga_in[1];
    logic        ext_gpio_fpga_in[2];
    logic        ext_gpio_fpga_in[3];
    logic        ext_gpio_fpga_in[4];
    logic        ext_gpio_fpga_in[5];
    logic        ext_gpio_fpga_in[6];
    logic        ext_gpio_fpga_in[7];
    logic        ext_gpio_fpga_oe[0];
    logic        ext_gpio_fpga_oe[1];
    logic        ext_gpio_fpga_oe[2];
    logic        ext_gpio_fpga_oe[3];
    logic        ext_gpio_fpga_oe[4];
    logic        ext_gpio_fpga_oe[5];
    logic        ext_gpio_fpga_oe[6];
    logic        ext_gpio_fpga_oe[7];
    logic        ext_gpio_fpga_out[0];
    logic        ext_gpio_fpga_out[1];
    logic        ext_gpio_fpga_out[2];
    logic        ext_gpio_fpga_out[3];
    logic        ext_gpio_fpga_out[4];
    logic        ext_gpio_fpga_out[5];
    logic        ext_gpio_fpga_out[6];
    logic        ext_gpio_fpga_out[7];
    logic        ext_gpio_oe_l;
    logic        ext_gpio_oe_l_oe;
    logic        led_oe_l;
    logic        led_oe_l_oe;
    // Ports for vp_1550_gpio_n_b1
    logic        ext_gpio_dir[0];
    logic        ext_gpio_dir[1];
    logic        ext_gpio_dir[2];
    logic        ext_gpio_dir[3];
    logic        ext_gpio_dir[4];
    logic        ext_gpio_dir[5];
    logic        ext_gpio_dir[6];
    logic        ext_gpio_dir[7];
    logic        ext_gpio_dir_oe[0];
    logic        ext_gpio_dir_oe[1];
    logic        ext_gpio_dir_oe[2];
    logic        ext_gpio_dir_oe[3];
    logic        ext_gpio_dir_oe[4];
    logic        ext_gpio_dir_oe[5];
    logic        ext_gpio_dir_oe[6];
    logic        ext_gpio_dir_oe[7];
    logic        led_l[4];
    logic        led_l[5];
    logic        led_l_oe[4];
    logic        led_l_oe[5];
    // Ports for vp_1550_gpio_n_b2
    logic        led_l[0];
    logic        led_l[1];
    logic        led_l[2];
    logic        led_l[3];
    logic        led_l[6];
    logic        led_l[7];
    logic        led_l_oe[0];
    logic        led_l_oe[1];
    logic        led_l_oe[2];
    logic        led_l_oe[3];
    logic        led_l_oe[6];
    logic        led_l_oe[7];
    // Ports for vp_1550_gpio_s_b0
    logic        fpga_avr_rxd;
    logic        fpga_ftdi_rxd;
    logic        fpga_i2c_mux_gnt;
    logic        irq_to_fpga;
    logic        qsfp_int_fpga_l;
    logic        fpga_avr_txd;
    logic        fpga_avr_txd_oe;
    logic        fpga_ftdi_txd;
    logic        fpga_ftdi_txd_oe;
    logic        fpga_i2c_req_l;
    logic        fpga_i2c_req_l_oe;
    logic        irq_to_avr;
    logic        irq_to_avr_oe;
    logic        test[1];
    logic        test_oe[1];
    // Ports for vp_1550_gpio_s_b1
    logic        mcio_vio_45_10_clk;
    logic        mcio_vio_in[0];
    logic        mcio_vio_in[1];
    logic        mcio_vio_in[2];
    logic        mcio_vio_in[3];
    logic        mcio_dir[0];
    logic        mcio_dir[1];
    logic        mcio_dir[2];
    logic        mcio_dir[3];
    logic        mcio_dir_45;
    logic        mcio_dir_45_oe;
    logic        mcio_dir_oe[0];
    logic        mcio_dir_oe[1];
    logic        mcio_dir_oe[2];
    logic        mcio_dir_oe[3];
    logic        mcio_vio_oe[0];
    logic        mcio_vio_oe[1];
    logic        mcio_vio_oe[2];
    logic        mcio_vio_oe[3];
    logic        mcio_vio_out[0];
    logic        mcio_vio_out[1];
    logic        mcio_vio_out[2];
    logic        mcio_vio_out[3];
    logic        test[2];
    logic        test_oe[2];
    // Ports for vp_1550_gpio_s_b2
    logic        fpga_sys_scl_in;
    logic        fpga_sys_sda_in;
    logic        mcio_scl_in;
    logic        mcio_sda_in;
    logic        fpga_sys_scl_oe;
    logic        fpga_sys_scl_out;
    logic        fpga_sys_sda_oe;
    logic        fpga_sys_sda_out;
    logic        mcio_oe1_l;
    logic        mcio_oe1_l_oe;
    logic        mcio_oe_45_l;
    logic        mcio_oe_45_l_oe;
    logic        mcio_scl_oe;
    logic        mcio_scl_out;
    logic        mcio_sda_oe;
    logic        mcio_sda_out;
    // Ports for vp_1550_pll_nw_2
    logic        pll_nw_2_ref0_312p5_clk;
    logic        vp_1550_pll_nw_2_lock;
    // Ports for vp_1550_pll_sw_2
    logic        pll_sw_2_ref1_312p5_clk;
    logic        vp_1550_pll_sw_2_lock;

//////////////////////////////////////
// End User Design Signal List Include File
//////////////////////////////////////
