onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_mlp_conv2d/clk
add wave -noupdate /tb_mlp_conv2d/reset_n
add wave -noupdate /tb_mlp_conv2d/chip_ready
add wave -noupdate /tb_mlp_conv2d/conv2d_error
add wave -noupdate /tb_mlp_conv2d/conv_done
add wave -noupdate /tb_mlp_conv2d/data_error
add wave -noupdate /tb_mlp_conv2d/test_timeout
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/awvalid
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/awready
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/awaddr
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/awlen
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/awid
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/awqos
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/awburst
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/awlock
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/awsize
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/awregion
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/wvalid
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/wready
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/wdata
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/wstrb
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/wlast
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/arready
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/arvalid
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/rdata
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/rlast
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/rresp
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/rvalid
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/rid
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/araddr
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/arlen
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/arid
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/arqos
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/arburst
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/arlock
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/arsize
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/arregion
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/rready
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/bvalid
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/bready
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/bresp
add wave -noupdate -group nap_in /tb_mlp_conv2d/i_conv2d/nap_in/bid
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/awvalid
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/awready
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/awaddr
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/awlen
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/awid
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/awqos
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/awburst
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/awlock
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/awsize
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/awregion
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/wvalid
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/wready
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/wdata
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/wstrb
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/wlast
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/arready
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/rdata
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/rlast
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/rresp
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/rvalid
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/rid
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/araddr
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/arlen
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/arid
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/arqos
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/arburst
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/arlock
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/arsize
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/arvalid
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/arregion
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/rready
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/bvalid
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/bready
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/bresp
add wave -noupdate -group nap_out /tb_mlp_conv2d/i_conv2d/nap_out/bid
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/i_clk
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/i_reset_n
add wave -noupdate -group DUT /tb_mlp_conv2d/i_conv2d/o_error
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
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/i_clk
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/i_reset_n
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/i_mlp_dout_valid
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/o_bram_wr_addr
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/o_bram_wren
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/o_bram_blk_wr_addr
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/o_in_fifo_wr
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/o_in_fifo_wr_addr_reset
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/o_in_fifo_rd_en
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/o_in_fifo_rd_addr
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/o_mlp_matrix_addr
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/o_mlp_din_sof
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/o_mlp_din_eof
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/o_matrix_done
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/matrix_calc_state
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/nap_in_state
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/nap_out_state
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/in_fifo_wr
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/in_fifo_wr_addr_reset
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/in_fifo_rd_en
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/lines_to_load
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/lines_to_load_m1
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/lines_to_load_ps
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/lines_to_load_ps_m1
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/lines_to_load_dec
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/lines_to_load_inc
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/lines_to_go
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/lines_to_go_dec
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/matrix_v_start
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/matrix_v_start_next
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/matrix_h_start
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/matrix_h_start_next
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/mlp_matrix_addr
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/mlp_matrix_addr_d
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/nap_in_addr
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/nap_in_addr_inc
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/nap_in_page_addr
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/matrix_v_count
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/matrix_h_count
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/in_fifo_rd_addr
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/line_read_num
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/line_read_num_next
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/last_calc
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/matrix_done
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/mlp_din_eof_d
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/mlp_din_eof_2d
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/mlp_din_eof_3d
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/mlp_din_sof_d
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/mlp_din_sof_2d
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/first_calc
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/bram_wr_addr
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/bram_wren
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/bram_loaded
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/bram_sel
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/bram_wr_addr_rst
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/arready_d
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/rready_d
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/rvalid_d
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/rlast_d
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/lines_to_go_zero
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/lines_to_load_zero
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/line_read_num_ls_height
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/matrix_v_start_ls_height
add wave -noupdate -group {dataflow control} /tb_mlp_conv2d/i_conv2d/i_control/matrix_h_start_ls_width
add wave -noupdate -group in_fifo /tb_mlp_conv2d/i_conv2d/i_in_fifo/i_clk
add wave -noupdate -group in_fifo /tb_mlp_conv2d/i_conv2d/i_in_fifo/i_reset_n
add wave -noupdate -group in_fifo /tb_mlp_conv2d/i_conv2d/i_in_fifo/i_wr_en
add wave -noupdate -group in_fifo /tb_mlp_conv2d/i_conv2d/i_in_fifo/i_wr_addr_reset
add wave -noupdate -group in_fifo /tb_mlp_conv2d/i_conv2d/i_in_fifo/i_data_in
add wave -noupdate -group in_fifo /tb_mlp_conv2d/i_conv2d/i_in_fifo/i_rd_en
add wave -noupdate -group in_fifo /tb_mlp_conv2d/i_conv2d/i_in_fifo/i_rd_addr
add wave -noupdate -group in_fifo /tb_mlp_conv2d/i_conv2d/i_in_fifo/o_data_out
add wave -noupdate -group in_fifo /tb_mlp_conv2d/i_conv2d/i_in_fifo/wr_addr
add wave -noupdate -group mlp_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/clk
add wave -noupdate -group mlp_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/reset_n
add wave -noupdate -group mlp_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/mlp_din
add wave -noupdate -group mlp_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/mlp_din_sof
add wave -noupdate -group mlp_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/mlp_din_eof
add wave -noupdate -group mlp_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/bram_rd_addr
add wave -noupdate -group mlp_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/bram_wr_addr
add wave -noupdate -group mlp_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/bram_blk_wr_addr
add wave -noupdate -group mlp_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/bram_din
add wave -noupdate -group mlp_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/bram_wren
add wave -noupdate -group mlp_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/dout_valid
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/i_clk
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/i_reset_n
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/i_b
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/i_b_wraddr
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/i_b_rdaddr
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/i_blk_wr_addr
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/i_wren
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/i_a
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/i_first
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/i_last
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/o_valid
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/bram_wr_data
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/a_del
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/first_del
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/wren_del
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/wraddr_del
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/rdaddr_del
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/blk_wr_addr
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/float
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/first_pipe
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/last_del
add wave -noupdate -group dot_product_multi /tb_mlp_conv2d/i_conv2d/i_mlp_multi/i_dp_16_8x8/last_pipe
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/i_clk
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/i_reset_n
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/i_wr_en
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/o_idle
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/o_bresp_error
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/data_hold
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/wr_en
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/axi_idle_count
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/bresp_error
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/data_in_d0
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/data_in_d1
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/data_in_d2
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/data_in_d3
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/mlp_req
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/mlp_req_next
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/mlp_req_next_d
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/mlp_ack
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/arb_count
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/arb_count_next
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/addr_state
add wave -noupdate -group out_fifo /tb_mlp_conv2d/i_conv2d/i_out_fifo/exp_id
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {85385 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 394
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {10500 ns}
