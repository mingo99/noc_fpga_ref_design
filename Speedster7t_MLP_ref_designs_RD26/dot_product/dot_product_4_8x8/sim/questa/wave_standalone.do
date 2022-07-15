onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Testbench /tb_dot_product_4_8x8/clk
add wave -noupdate -group Testbench /tb_dot_product_4_8x8/a
add wave -noupdate -group Testbench /tb_dot_product_4_8x8/b
add wave -noupdate -group Testbench /tb_dot_product_4_8x8/sum
add wave -noupdate -group Testbench /tb_dot_product_4_8x8/first
add wave -noupdate -group Testbench /tb_dot_product_4_8x8/last
add wave -noupdate -group Testbench /tb_dot_product_4_8x8/valid
add wave -noupdate -group Testbench /tb_dot_product_4_8x8/expected
add wave -noupdate -group Testbench /tb_dot_product_4_8x8/exp_valid
add wave -noupdate -group Testbench /tb_dot_product_4_8x8/compare_fail
add wave -noupdate -group Testbench /tb_dot_product_4_8x8/test_fail
add wave -noupdate -group DUT /tb_dot_product_4_8x8/DUT/i_clk
add wave -noupdate -group DUT /tb_dot_product_4_8x8/DUT/i_a
add wave -noupdate -group DUT /tb_dot_product_4_8x8/DUT/i_b
add wave -noupdate -group DUT /tb_dot_product_4_8x8/DUT/i_first
add wave -noupdate -group DUT /tb_dot_product_4_8x8/DUT/i_last
add wave -noupdate -group DUT /tb_dot_product_4_8x8/DUT/o_sum
add wave -noupdate -group DUT /tb_dot_product_4_8x8/DUT/o_valid
add wave -noupdate -group DUT /tb_dot_product_4_8x8/DUT/mlp_out
add wave -noupdate -group DUT /tb_dot_product_4_8x8/DUT/last
add wave -noupdate -group DUT /tb_dot_product_4_8x8/DUT/float
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ps} {20282 ps}
