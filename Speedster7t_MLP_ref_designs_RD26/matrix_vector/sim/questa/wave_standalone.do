onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/clk
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/tb_i_matrix
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/tb_i_matrix_wren
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/tb_i_matrix_wrpause
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/tb_i_vector
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/tb_i_first
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/tb_i_last
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/tb_i_pause
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/tb_o_sum
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/tb_o_first_sum
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/tb_o_last_sum
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/tb_o_pause_sum
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/test_fail
add wave -noupdate -group Testbench /tb_mvm_8mlp_16int8_earlyout/compare_fail
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/i_clk
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/i_matrix
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/i_matrix_wren
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/i_matrix_wrpause
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/i_v
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/i_first
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/i_last
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/i_pause
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/o_sum
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/o_first
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/o_last
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/o_pause
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/v_lo
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/v_hi
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/wr_lsb
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/wr_base
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/wrblk_addr
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/wraddr
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/wrblk_addr_next
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/computing
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/lram_reading
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/cycle_count
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/bram_rdaddr
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/sum_valid
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/waiting_first
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/output_active
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/bram_din2mlp_din
add wave -noupdate -group DUT /tb_mvm_8mlp_16int8_earlyout/DUT/bram_dout2mlp_din
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
WaveRestoreZoom {11230236 ps} {11738606 ps}
