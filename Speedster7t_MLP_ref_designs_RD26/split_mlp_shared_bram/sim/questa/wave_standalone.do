onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/tick_count
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/clk
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/bram_a_din
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/bram_a_wraddr
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/bram_a_wren
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/bram_b_group
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/bram_b_din
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/bram_b_wraddr
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/bram_b_wren
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/bram_a_rdaddr
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/bram_b_rdaddr
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/first
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/pause
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/last
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/result_rden
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/result_rstn
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/result_empty
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/result_full
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/result_almost_empty
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/result_almost_full
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/result
add wave -noupdate -group Testbench /tb_split_mlp_shared_bram/result_valid
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_clk
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_bram_a_din
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_bram_a_wraddr
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_bram_a_wren
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_bram_b_group
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_bram_b_din
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_bram_b_wraddr
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_bram_b_wren
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_bram_a_rdaddr
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_bram_b_rdaddr
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_first
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_pause
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_last
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_result_rden
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/i_result_rstn
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/o_result_empty
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/o_result_full
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/o_result_almost_empty
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/o_result_almost_full
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/o_result
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/o_result_valid
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_bram_a_din
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_bram_a_wraddr
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_bram_a_wren
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_bram_b_group
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_bram_b_din
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_bram_b_wraddr
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_bram_b_wren
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_bram_a_rdaddr
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_bram_b_rdaddr
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_first
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_pause
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_last
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_result_rden
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_result_rstn
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_result_empty
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_result_full
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_result_almost_empty
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_result_almost_full
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_result
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/reg_result_valid
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/result_empty
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/result_full
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/result_almost_empty
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/result_almost_full
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/result
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/result_valid
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/bram_b_din
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/bram_b_wraddr
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/bram_b_wren_selected
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/bram_b_wren
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/result_1
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/result_1_valid
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/result_0
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/result_0_valid
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/group_chain_result
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/group_chain_result_valid
add wave -noupdate -group DUT /tb_split_mlp_shared_bram/DUT/bram_b_we
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 205
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
WaveRestoreZoom {0 ps} {298734 ps}
