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
// VectorPath rev 1 Ports
//   Include this file in a design top level module declaration
//   NOTE : This file should be the end of the port declarations,
//          If not, then add a "," after the include statement
// ------------------------------------------------------------------

    // GPIO tristate bus
    input  wire [7:0]                   ext_gpio_fpga_in,
    output wire [7:0]                   ext_gpio_fpga_out,
    output wire [7:0]                   ext_gpio_fpga_oe,

    // GPIO direction
    output wire [7:0]                   ext_gpio_dir,
    output wire [7:0]                   ext_gpio_dir_oe,

    // GPIO OE, (on the board)
    output wire                         ext_gpio_oe_l,
    output wire                         ext_gpio_oe_l_oe,

    // LEDs
    output wire [7:0]                   led_l,
    output wire [7:0]                   led_l_oe,
    output wire                         led_oe_l,
    output wire                         led_oe_l_oe,

    input  wire                         fpga_rst_l,     // Reset from BCM
    input  wire                         irq_to_fpga,

    input  wire                         fpga_avr_rxd,
    output wire                         fpga_avr_txd,
    output wire                         fpga_avr_txd_oe,
    output wire                         irq_to_avr,
    output wire                         irq_to_avr_oe,

    input  wire                         fpga_i2c_mux_gnt,
    output wire                         fpga_i2c_req_l,
    output wire                         fpga_i2c_req_l_oe,

    input  wire                         qsfp_int_fpga_l,

    input  wire                         fpga_ftdi_rxd,
    output wire                         fpga_ftdi_txd,
    output wire                         fpga_ftdi_txd_oe,

    output wire [2:1]                   test,
    output wire [2:1]                   test_oe,

    // I2C
    input  wire                         fpga_sys_scl_in,
    output wire                         fpga_sys_scl_out,
    output wire                         fpga_sys_scl_oe,
    input  wire                         fpga_sys_sda_in,
    output wire                         fpga_sys_sda_out,
    output wire                         fpga_sys_sda_oe,

    // MCIO
    output wire [3:0]                   mcio_dir,
    output wire [3:0]                   mcio_dir_oe,
    output wire                         mcio_dir_45,
    output wire                         mcio_dir_45_oe,

    input  wire                         mcio_scl_in,
    input  wire                         mcio_sda_in,

    input  wire [3:0]                   mcio_vio_in,
    output wire [3:0]                   mcio_vio_out,
    output wire [3:0]                   mcio_vio_oe,
    input  wire                         mcio_vio_45_10_clk,

    output wire                         mcio_oe1_l,
    output wire                         mcio_oe1_l_oe,
    output wire                         mcio_oe_45_l,
    output wire                         mcio_oe_45_l_oe,

    output wire                         mcio_scl_oe,
    output wire                         mcio_scl_out,
    output wire                         mcio_sda_oe,
    output wire                         mcio_sda_out,

    // Internally looped clocks that go back to the onboard clock generator
    input  wire                         pll_nw_2_ref0_312p5_clk,
    input  wire                         vp_pll_nw_2_lock,

    input  wire                         pll_sw_2_ref1_312p5_clk,
    input  wire                         vp_pll_sw_2_lock


