onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Testbench /tb_pcie_ref_design/clk
add wave -noupdate -group Testbench /tb_pcie_ref_design/serdes_ref_clk
add wave -noupdate -group Testbench /tb_pcie_ref_design/reset_n
add wave -noupdate -group Testbench /tb_pcie_ref_design/test_start
add wave -noupdate -group Testbench /tb_pcie_ref_design/test_fail
add wave -noupdate -group Testbench /tb_pcie_ref_design/mstr_test_fail
add wave -noupdate -group Testbench /tb_pcie_ref_design/mstr_test_fail_d
add wave -noupdate -group Testbench /tb_pcie_ref_design/chip_ready
add wave -noupdate -group Testbench /tb_pcie_ref_design/test_timeout
add wave -noupdate -group Testbench /tb_pcie_ref_design/test_complete_pciex16
add wave -noupdate -group Testbench /tb_pcie_ref_design/test_complete_pciex8
add wave -noupdate -group Testbench /tb_pcie_ref_design/test_complete
add wave -noupdate -group Testbench /tb_pcie_ref_design/mstr_test_complete
add wave -noupdate -group Testbench /tb_pcie_ref_design/pll_1_lock
add wave -noupdate -group Testbench /tb_pcie_ref_design/pciex8_bfm_test_done
add wave -noupdate -group Testbench /tb_pcie_ref_design/pciex16_bfm_test_done
add wave -noupdate -group Testbench /tb_pcie_ref_design/pciex8_rtl_test_done
add wave -noupdate -group Testbench /tb_pcie_ref_design/pciex16_rtl_test_done
add wave -noupdate -group Testbench /tb_pcie_ref_design/pci_express_x16_status_flr_pf_active
add wave -noupdate -group Testbench /tb_pcie_ref_design/pci_express_x16_status_flr_vf_active
add wave -noupdate -group Testbench /tb_pcie_ref_design/pci_express_x16_status_ltssm_state
add wave -noupdate -group Testbench /tb_pcie_ref_design/pci_express_x8_status_ltssm_state
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/i_clk
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/i_reset_n
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/i_start
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/pll_1_lock
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/pci_express_x16_status_ltssm_state
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/pci_express_x8_status_ltssm_state
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/pci_express_x16_status_flr_pf_active
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/pci_express_x16_status_flr_vf_active
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/o_mstr_test_complete
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/o_mstr_test_complete_oe
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/o_fail
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/o_fail_oe
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/pcie16_link_ctr
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/pcie8_link_ctr
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/pcie16_link_ready
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/pcie8_link_ready
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/nap_rstn
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/start_pipe_pcie8
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/start_pipe_pcie16
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/ready_del_pipe_pcie8
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/ready_del_pipe_pcie16
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/start_del_pcie8
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/start_del_pcie16
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/o_fail_x16
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/o_fail_x8
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/o_test_complete_x16
add wave -noupdate -group DUT /tb_pcie_ref_design/DUT/o_test_complete_x8
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 274
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
WaveRestoreZoom {0 ps} {41364750 ps}
