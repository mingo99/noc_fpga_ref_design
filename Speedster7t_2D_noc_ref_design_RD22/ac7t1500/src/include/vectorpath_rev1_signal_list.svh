// ------------------------------------------------------------------
//
// Copyright (c) 2021 Achronix Semiconductor Corp.
// All Rights Reserved.
//
// This Software constitutes an unpublished work and contains
// valuable proprietary information and trade secrets belonging
// to Achronix Semiconductor Corp.
//
// Permission is hereby granted to use this Software including
// without limitation the right to copy, modify, merge or distribute
// copies of the software subject to the following condition:
//
// The above copyright notice and this permission notice shall
// be included in in all copies of the Software.
//
// The Software is provided “as is” without warranty of any kind
// expressed or implied, including  but not limited to the warranties
// of merchantability fitness for a particular purpose and non-infringement.
// In no event shall the copyright holder be liable for any claim,
// damages, or other liability for any damages or other liability,
// whether an action of contract, tort or otherwise, arising from, 
// out of, or in connection with the Software
//
// ------------------------------------------------------------------
// VectorPath rev 1 signals
//   Include this file in the testbench declaration
// ------------------------------------------------------------------

    logic [7:0]                   ext_gpio_fpga_in;
    logic [7:0]                   ext_gpio_fpga_out;
    logic [7:0]                   ext_gpio_fpga_oe;

    // GPIO direction
    logic [7:0]                   ext_gpio_dir;
    logic [7:0]                   ext_gpio_dir_oe;

    // GPIO OE, (on the board)
    logic                         ext_gpio_oe_l;
    logic                         ext_gpio_oe_l_oe;

    logic [7:0]                   led_l;
    logic [7:0]                   led_l_oe;
    logic                         led_oe_l;
    logic                         led_oe_l_oe;

    logic                         fpga_rst_l;
    logic                         irq_to_fpga;

    logic                         fpga_avr_rxd;
    logic                         fpga_avr_txd;
    logic                         fpga_avr_txd_oe;
    logic                         irq_to_avr;
    logic                         irq_to_avr_oe;

    logic                         fpga_ftdi_rxd;
    logic                         fpga_ftdi_txd;
    logic                         fpga_ftdi_txd_oe;

    logic                         fpga_i2c_mux_gnt;
    logic                         fpga_i2c_req_l;
    logic                         fpga_i2c_req_l_oe;

    logic                         qsfp_int_fpga_l;

    logic [2:1]                   test;
    logic [2:1]                   test_oe;

    // I2C
    logic                         fpga_sys_scl_in;
    logic                         fpga_sys_scl_out;
    logic                         fpga_sys_scl_oe;
    logic                         fpga_sys_sda_in;
    logic                         fpga_sys_sda_out;
    logic                         fpga_sys_sda_oe;

    // MCIO
    logic [3:0]                   mcio_dir;
    logic [3:0]                   mcio_dir_oe;
    logic                         mcio_dir_45;
    logic                         mcio_dir_45_oe;

    logic                         mcio_scl_in;
    logic                         mcio_sda_in;

    logic [3:0]                   mcio_vio_in;
    logic [3:0]                   mcio_vio_out;
    logic [3:0]                   mcio_vio_oe;
    logic                         mcio_vio_45_10_clk;

    logic                         mcio_oe1_l;
    logic                         mcio_oe1_l_oe;
    logic                         mcio_oe_45_l;
    logic                         mcio_oe_45_l_oe;

    logic                         mcio_scl_oe;
    logic                         mcio_scl_out;
    logic                         mcio_sda_oe;
    logic                         mcio_sda_out;

    logic                         pll_nw_2_ref0_312p5_clk;
    logic                         vp_pll_nw_2_lock;

    logic                         pll_sw_2_ref1_312p5_clk;
    logic                         vp_pll_sw_2_lock;

