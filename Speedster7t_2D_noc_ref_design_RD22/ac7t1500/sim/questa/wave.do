onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/send_clk
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/chk_clk
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/reset_n
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_start_h_send
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_start_h_chk
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_start_v_send
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_start_v_chk
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_start_axi
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_fail_h
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_fail_v
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_fail_axi
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_fail
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_fail_d
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/chip_ready
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_timeout
add wave -noupdate -group Testbench /tb_noc_2d_ref_design/test_complete
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/i_send_clk
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/i_chk_clk
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/i_reg_clk
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/pll_send_clk_lock
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/pll_chk_clk_lock
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/ext_gpio_fpga_in
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/ext_gpio_fpga_out
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/ext_gpio_fpga_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/ext_gpio_dir
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/ext_gpio_dir_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/ext_gpio_oe_l
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/ext_gpio_oe_l_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/led_l
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/led_l_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/led_oe_l
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/led_oe_l_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_rst_l
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/irq_to_fpga
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_avr_rxd
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_avr_txd
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_avr_txd_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/irq_to_avr
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/irq_to_avr_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_i2c_mux_gnt
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_i2c_req_l
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_i2c_req_l_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/qsfp_int_fpga_l
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_ftdi_rxd
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_ftdi_txd
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_ftdi_txd_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/test
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/test_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_sys_scl_in
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_sys_scl_out
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_sys_scl_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_sys_sda_in
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_sys_sda_out
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/fpga_sys_sda_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_dir
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_dir_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_dir_45
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_dir_45_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_scl_in
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_sda_in
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_vio_in
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_vio_out
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_vio_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_vio_45_10_clk
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_oe1_l
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_oe1_l_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_oe_45_l
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_oe_45_l_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_scl_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_scl_out
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_sda_oe
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/mcio_sda_out
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/pll_nw_2_ref0_312p5_clk
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/vp_pll_nw_2_lock
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/pll_sw_2_ref1_312p5_clk
add wave -noupdate -group DUT /tb_noc_2d_ref_design/DUT/vp_pll_sw_2_lock
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 273
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits fs
update
WaveRestoreZoom {0 ps} {42755564 ps}
