onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Testbench /tb_mlp_conv2d/clk
add wave -noupdate -group Testbench /tb_mlp_conv2d/reset_n
add wave -noupdate -group Testbench /tb_mlp_conv2d/chip_ready
add wave -noupdate -group Testbench /tb_mlp_conv2d/conv2d_error
add wave -noupdate -group Testbench /tb_mlp_conv2d/conv_done
add wave -noupdate -group Testbench /tb_mlp_conv2d/data_error
add wave -noupdate -group Testbench /tb_mlp_conv2d/test_timeout
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/i_clk
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/i_reset_n
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/pll_1_lock
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/pll_2_lock
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/o_conv_done
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/o_conv_done_oe
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/o_error
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/o_error_oe
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/output_rstn_nap_in
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/error_valid_nap_in
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/error_info_nap_in
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/output_rstn_nap_out
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/error_valid_nap_out
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/error_info_nap_out
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/in_fifo_wr
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/in_fifo_rd_en
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/in_fifo_rd_addr
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/in_fifo_wr_addr_reset
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/in_line_data
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/bram_wr_addr
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/bram_blk_wr_addr
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/bram_wren
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/mlp_data_out
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/mlp_data_out_valid
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/mlp_multi_data_out_valid
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/mlp_matrix_addr
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/in_line_data_sof
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/in_line_data_eof
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/matrix_done
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/out_fifo_idle
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/out_fifo_bresp_error
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/sys_rstn
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 222
configure wave -valuecolwidth 132
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {928 ps}
