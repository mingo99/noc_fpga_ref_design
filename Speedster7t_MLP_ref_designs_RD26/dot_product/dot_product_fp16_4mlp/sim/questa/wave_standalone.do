onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/clk
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/a
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/b
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/sum
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/first
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/last
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/valid
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/exp_valid
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/expected
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/exp_valid_d
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/expected_d
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/compare_fail
add wave -noupdate -group Testbench /tb_dot_product_fp16_4mlp/test_fail
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/i_clk
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/i_a
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/i_b
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/i_first
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/i_last
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/o_sum
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/o_valid
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/reg_a
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/reg_b
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/reg_first
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/reg_last
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/reg_sum
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/reg_valid
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/sum
add wave -noupdate -group DUT /tb_dot_product_fp16_4mlp/DUT/valid
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
WaveRestoreZoom {55733 ps} {76015 ps}
