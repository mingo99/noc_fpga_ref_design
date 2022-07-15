onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Testbench /tb_ethernet_ref_design/usr_clk
add wave -noupdate -group Testbench /tb_ethernet_ref_design/ff_clk
add wave -noupdate -group Testbench /tb_ethernet_ref_design/ref_clk
add wave -noupdate -group Testbench /tb_ethernet_ref_design/mac_clk
add wave -noupdate -group Testbench /tb_ethernet_ref_design/reset_n
add wave -noupdate -group Testbench /tb_ethernet_ref_design/serdes_reset_n
add wave -noupdate -group Testbench /tb_ethernet_ref_design/chip_ready
add wave -noupdate -group Testbench /tb_ethernet_ref_design/test_start
add wave -noupdate -group Testbench /tb_ethernet_ref_design/test_timeout
add wave -noupdate -group Testbench /tb_ethernet_ref_design/test_complete
add wave -noupdate -group Testbench /tb_ethernet_ref_design/plls_lock
add wave -noupdate -group Testbench /tb_ethernet_ref_design/lb_pkt_num
add wave -noupdate -group Testbench /tb_ethernet_ref_design/lb_checksum_error
add wave -noupdate -group Testbench /tb_ethernet_ref_design/lb_pkt_size_error
add wave -noupdate -group Testbench /tb_ethernet_ref_design/lb_payload_error
add wave -noupdate -group Testbench /tb_ethernet_ref_design/lb_fail
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_RX_N0
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_RX_N1
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_RX_N2
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_RX_N3
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_RX_P0
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_RX_P1
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_RX_P2
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_RX_P3
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_RX_N0
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_RX_N1
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_RX_N2
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_RX_N3
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_RX_P0
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_RX_P1
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_RX_P2
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_RX_P3
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_TX_N0
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_TX_N1
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_TX_N2
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_TX_N3
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_TX_P0
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_TX_P1
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_TX_P2
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N2_TX_P3
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_TX_N0
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_TX_N1
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_TX_N2
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_TX_N3
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_TX_P0
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_TX_P1
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_TX_P2
add wave -noupdate -group Testbench /tb_ethernet_ref_design/SRDS_N3_TX_P3
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/i_reset_n
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/i_start
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/i_eth_clk
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/pll_usr_lock
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/pll_eth_ref_lock
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/pll_eth_ff_lock
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/pll_noc_lock
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/o_checksum_error
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/o_pkt_size_error
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/o_payload_error
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/o_pkt_num
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/o_checksum_error_oen
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/o_pkt_size_error_oen
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/o_payload_error_oen
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_ff_clk_divby2
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_ff_clk_divby2
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_ref_clk_divby2
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_pause_on
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_tx_smhold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_xoff_gen
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_tx_ovr_err
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_tx_underflow
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_pause_on
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_tx_smhold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_xoff_gen
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_tx_ovr_err
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_tx_underflow
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_rx_buffer0_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_rx_buffer1_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_rx_buffer2_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_rx_buffer3_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_tx_buffer0_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_tx_buffer1_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_tx_buffer2_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m0_tx_buffer3_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_rx_buffer0_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_rx_buffer1_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_rx_buffer2_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_rx_buffer3_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_tx_buffer0_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_tx_buffer1_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_tx_buffer2_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/ethernet_1_m1_tx_buffer3_at_threshold
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/eth_rstn
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/tx_ts
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/start_int
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_seq_id_dval
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_fifo_empty
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_fifo_aempty
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_fifo_full
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_fifo_afull
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_seq_id0
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_seq_id1
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_seq_id2
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_seq_id3
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_stream_id0
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_stream_id1
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_stream_id2
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_stream_id3
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/gen_enable_sel
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/gen_enable_q
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_rate_limit_count
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_rate_enable
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/active_ch_sum
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/active_ch0
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/active_ch1
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/active_ch2
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/active_ch3
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/eth_rx_chk_ready
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/current_seq_id
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/seq_id_valid_ch
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/seq_id_valid_match
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/seq_id_valid_match_d
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/stream_id_match
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/rx_channel_fifo_wr
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/chk_checksum_error
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/chk_pkt_size_error
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/chk_payload_error
add wave -noupdate -group DUT /tb_ethernet_ref_design/DUT/pkt_num_total
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {567500 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 458
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
WaveRestoreZoom {77862191 ps} {78262052 ps}
