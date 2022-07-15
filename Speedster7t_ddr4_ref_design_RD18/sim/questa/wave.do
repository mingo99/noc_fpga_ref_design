onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Testbench /tb_ddr4_ref_design/clk
add wave -noupdate -group Testbench /tb_ddr4_ref_design/training_clk
add wave -noupdate -group Testbench /tb_ddr4_ref_design/reset_n
add wave -noupdate -group Testbench /tb_ddr4_ref_design/chip_ready
add wave -noupdate -group Testbench /tb_ddr4_ref_design/count_value
add wave -noupdate -group Testbench /tb_ddr4_ref_design/count_done
add wave -noupdate -group Testbench /tb_ddr4_ref_design/test_start
add wave -noupdate -group Testbench /tb_ddr4_ref_design/test_fail
add wave -noupdate -group Testbench /tb_ddr4_ref_design/test_fail_d
add wave -noupdate -group Testbench /tb_ddr4_ref_design/test_timeout
add wave -noupdate -group Testbench /tb_ddr4_ref_design/test_complete
add wave -noupdate -group Testbench /tb_ddr4_ref_design/training_rstn
add wave -noupdate -group Testbench /tb_ddr4_ref_design/training_done
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ALERT_n
add wave -noupdate -group Testbench /tb_ddr4_ref_design/DDR4_S0_BP_UNUSED
add wave -noupdate -group Testbench /tb_ddr4_ref_design/VREF
add wave -noupdate -group Testbench /tb_ddr4_ref_design/RESET_n
add wave -noupdate -group Testbench /tb_ddr4_ref_design/DQ
add wave -noupdate -group Testbench /tb_ddr4_ref_design/DQS_c
add wave -noupdate -group Testbench /tb_ddr4_ref_design/DQS_t
add wave -noupdate -group Testbench /tb_ddr4_ref_design/DM_n
add wave -noupdate -group Testbench /tb_ddr4_ref_design/DM_DBI_UDQS
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ADDR
add wave -noupdate -group Testbench /tb_ddr4_ref_design/CK_c
add wave -noupdate -group Testbench /tb_ddr4_ref_design/CK_t
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ACT_n
add wave -noupdate -group Testbench /tb_ddr4_ref_design/BA
add wave -noupdate -group Testbench /tb_ddr4_ref_design/BG
add wave -noupdate -group Testbench /tb_ddr4_ref_design/CS_n
add wave -noupdate -group Testbench /tb_ddr4_ref_design/PARITY
add wave -noupdate -group Testbench /tb_ddr4_ref_design/CKE
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ODT
add wave -noupdate -group Testbench /tb_ddr4_ref_design/C
add wave -noupdate -group Testbench /tb_ddr4_ref_design/TEN
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ZQ
add wave -noupdate -group Testbench /tb_ddr4_ref_design/PWR
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awvalid
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awready
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awaddr
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awlen
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awid
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awqos
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awburst
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awlock
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awsize
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awregion
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awcache
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awprot
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_wvalid
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_wready
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_wdata
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_wstrb
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_wlast
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arready
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arvalid
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_araddr
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arlen
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arid
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arqos
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arburst
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arlock
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arsize
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arregion
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arcache
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arprot
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_rready
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_rvalid
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_rdata
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_rlast
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_rresp
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_rid
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_bvalid
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_bready
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_bresp
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_bid
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_clk
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_clk_alt
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_rstn
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arex_auto_precharge
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arex_parity
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arex_poison
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_arex_urgent
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_rex_parity
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awex_auto_precharge
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awex_parity
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awex_poison
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_awex_urgent
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_wex_parity
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_axi_arpoison_irq
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dc_axi_awpoison_irq
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_dfi_alert_err_irq
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_ecc_corrected_err_irq
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_ecc_corrected_err_irq_fault
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_ecc_uncorrected_err_irq
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_ecc_uncorrected_err_irq_fault
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_noc_axi_arpoison_irq
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_noc_axi_awpoison_irq
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_par_raddr_err_irq
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_par_raddr_err_irq_fault
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_par_rdata_err_irq
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_par_rdata_err_irq_fault
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_par_waddr_err_irq
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_par_waddr_err_irq_fault
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_par_wdata_err_irq
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_par_wdata_err_irq_fault
add wave -noupdate -group Testbench /tb_ddr4_ref_design/ddr4_1_phy_irq_n
add wave -noupdate -group Testbench /tb_ddr4_ref_design/pll_1_lock
add wave -noupdate -group Testbench /tb_ddr4_ref_design/pll_2_lock
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/i_clk
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/i_reset_n
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/i_start
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/i_training_clk
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/i_training_rstn
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/pll_1_lock
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/pll_2_lock
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_clk
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_clk_alt
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_rstn
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awvalid
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awready
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awaddr
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awlen
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awid
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awqos
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awburst
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awlock
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awsize
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awregion
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awcache
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awprot
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_wvalid
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_wready
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_wdata
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_wstrb
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_wlast
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arready
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arvalid
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_araddr
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arlen
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arid
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arqos
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arburst
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arlock
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arsize
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arregion
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arcache
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arprot
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_rready
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_rvalid
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_rdata
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_rlast
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_rresp
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_rid
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_bvalid
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_bready
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_bresp
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_bid
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arex_auto_precharge
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arex_parity
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arex_poison
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_arex_urgent
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_rex_parity
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awex_auto_precharge
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awex_parity
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awex_poison
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_awex_urgent
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_wex_parity
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_axi_arpoison_irq
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dc_axi_awpoison_irq
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_dfi_alert_err_irq
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_ecc_corrected_err_irq
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_ecc_corrected_err_irq_fault
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_ecc_uncorrected_err_irq
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_ecc_uncorrected_err_irq_fault
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_noc_axi_arpoison_irq
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_noc_axi_awpoison_irq
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_par_raddr_err_irq
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_par_raddr_err_irq_fault
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_par_rdata_err_irq
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_par_rdata_err_irq_fault
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_par_waddr_err_irq
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_par_waddr_err_irq_fault
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_par_wdata_err_irq
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_par_wdata_err_irq_fault
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/ddr4_1_phy_irq_n
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/o_fail
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/o_fail_oe
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/o_xact_done
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/o_xact_done_oe
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/o_training_done
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/o_training_done_oe
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/nap_fail
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/dci_fail
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/nap_done
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/dci_done
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/dci_rstn
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/nap_rstn
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/training_rstn_sync
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/training_rstn_pipe
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/train_done
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/output_rstn_nap
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/error_valid_nap
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/error_info_nap
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/test_gen_count
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/test_rx_count
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/start_d
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/axi_wr_enable
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/wr_addr
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/rd_addr
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/wr_len
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/rd_len
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/written_valid
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/pkt_compared
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/continuous_test
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/fifo_data_in
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/fifo_data_out
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/fifo_rden
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/fifo_empty
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/fifo_full
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/test_gen_count_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/test_rx_count_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/axi_wr_enable_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/start_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/wr_addr_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/rd_addr_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/wr_len_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/rd_len_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/written_valid_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/pkt_compared_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/continuous_test_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/fifo_data_in_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/fifo_data_out_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/fifo_rden_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/fifo_empty_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/fifo_full_dci
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/start_dci_sync_in
add wave -noupdate -group DUT /tb_ddr4_ref_design/DUT/start_dci_1
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/i_clk
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/i_reset_n
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/i_start
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/i_enable
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/o_addr_written
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/o_len_written
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/o_written_valid
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/axi_data_out
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/axi_addr_out
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/gen_addr
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/addr_written
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/len_written
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/written_valid
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/data_start
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/data_enable
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/new_data_val
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/addr_start
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/addr_enable
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/burst_len
add wave -noupdate -group axi_pkt_gen_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_gen_nap/wr_state
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/i_clk
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/i_reset_n
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/i_xact_avail
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/i_xact_addr
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/i_xact_len
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/o_xact_read
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/o_pkt_compared
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/o_pkt_error
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/exp_axi_data
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/rd_axi_data
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/rid
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/data_enable
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/new_data_read
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/new_data_read_d
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/gen_new_value
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/pkt_compared
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/rd_state
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/data_error
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/id_error
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/mismatch_message_count
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/arready_d
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/rvalid_d
add wave -noupdate -group axi_pkt_chk_nap /tb_ddr4_ref_design/DUT/i_axi_pkt_chk_nap/rlast_d
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/awvalid
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/awready
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/awaddr
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/awlen
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/awid
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/awqos
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/awburst
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/awlock
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/awsize
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/awregion
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/wvalid
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/wready
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/wdata
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/wstrb
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/wlast
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/arready
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/rdata
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/rlast
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/rresp
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/rvalid
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/rid
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/araddr
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/arlen
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/arid
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/arqos
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/arburst
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/arlock
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/arsize
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/arvalid
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/arregion
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/rready
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/bvalid
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/bready
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/bresp
add wave -noupdate -group nap /tb_ddr4_ref_design/DUT/nap/bid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {44744 ps} 0} {{Cursor 2} {2234106 ps} 0}
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
WaveRestoreZoom {12282488 ps} {62887238 ps}
