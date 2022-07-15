
set rtl_verilog_files {
default_nettype.v
reset_processor.sv
nap_slave_wrapper.sv
nap_master_wrapper.sv    
axi_bram_responder.sv
random_seq_engine.sv
axi_pkt_gen.sv
axi_pkt_chk.sv
axi_gen_chk.sv
acx_axi_req_fifo.sv
acx_axi_slave_register.sv
acx_slave_reg_cfg64.sv
acx_slave_reg_cfg.sv
acx_slave_reg_cnt.sv
acx_slave_reg_core.sv
acx_slave_reg_dout_mux.sv
acx_slave_reg_if.sv
acx_slave_reg_irq_rc.sv
acx_slave_reg_irq.sv
acx_slave_reg_sta.sv
axi_nap_register_set.sv
pcie_ref_design_top.sv
}

# No VHDL files in project
# set rtl_vhdl_files {
# }

set synplify_constraints_files {
synplify_constraints.sdc
synplify_constraints.fdc
}

set ace_constraints_files {
../ioring/pcie_ref_design_top_ioring.sdc
../ioring/pcie_ref_design_top_ioring_delays_C2_850mV_0C.sdc
../ioring/pcie_ref_design_top_ioring.pdc
ace_constraints.sdc
ace_placements.pdc
../ioring/pcie_ref_design_top_ioring_util.xml
../ioring/pcie_ref_design_top_ioring_bitstream0.hex
../ioring/pcie_ref_design_top_ioring_bitstream1.hex
}

set synplify_option_files {
synplify_options.tcl
}

set ace_options_files {
ace_options.tcl
}


# files relative to ace/ directory
set multi_acxip_files {
../acxip/clock_io_bank.acxip
../acxip/gpio_bank_north.acxip
../acxip/noc.acxip
../acxip/pll_1.acxip
../acxip/pci_express_x16.acxip
../acxip/pci_express_x8.acxip
}


#tb_noc_memory_behavioural.sv

set tb_verilog_files {
# pciesvc_device_serdes_x16_model_config.sv
pcie_bfm_testcase.sv
# pcie_rtl_testcase.sv
tb_pcie_ref_design.sv
}

set tb_vhdl_files {
}

