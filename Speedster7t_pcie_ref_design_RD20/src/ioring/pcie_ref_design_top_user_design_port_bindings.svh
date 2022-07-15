//////////////////////////////////////
// ACE GENERATED VERILOG INCLUDE FILE
// Generated on: 2021.05.04 at 06:44:45 PDT
// By: ACE 8.3.3
// From project: pcie_ref_design_top
//////////////////////////////////////
// User Design Port Binding Include File
//////////////////////////////////////

//////////////////////////////////////
// User Design Ports
//////////////////////////////////////
    // Ports for clock_io_bank
    // Ports for gpio_bank_north
`ifdef ACX_GPIO_N_FULL
`ACX_BIND_USER_DESIGN_PORT(i_reset_n, i_user_11_09_lut_13[15])
`ACX_BIND_USER_DESIGN_PORT(i_start, i_user_11_09_lut_13[23])
`ACX_BIND_USER_DESIGN_PORT(o_fail, o_user_11_09_lut_14[8])
`ACX_BIND_USER_DESIGN_PORT(o_fail_oe, o_user_11_09_lut_12[19])
`ACX_BIND_USER_DESIGN_PORT(o_mstr_test_complete, o_user_11_09_lut_14[0])
`ACX_BIND_USER_DESIGN_PORT(o_mstr_test_complete_oe, o_user_11_09_lut_12[18])
`endif
    // Ports for noc
    // Ports for pci_express_x16
    // Status
`ACX_BIND_USER_DESIGN_PORT(pci_express_x16_status_flr_pf_active[0], i_user_10_09_mlp_00[10])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x16_status_flr_pf_active[1], i_user_10_09_mlp_00[11])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x16_status_flr_pf_active[2], i_user_10_09_mlp_00[12])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x16_status_flr_pf_active[3], i_user_10_09_mlp_00[13])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x16_status_flr_vf_active, i_user_10_09_mlp_00[9])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x16_status_ltssm_state[0], i_user_10_09_lut_00[1])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x16_status_ltssm_state[1], i_user_10_09_lut_00[2])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x16_status_ltssm_state[2], i_user_10_09_lut_00[3])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x16_status_ltssm_state[3], i_user_10_09_lut_00[4])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x16_status_ltssm_state[4], i_user_10_09_lut_00[5])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x16_status_ltssm_state[5], i_user_10_09_lut_00[6])
    // Ports for pci_express_x8
    // Status
`ACX_BIND_USER_DESIGN_PORT(pci_express_x8_status_ltssm_state[0], i_user_03_09_lut_08[20])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x8_status_ltssm_state[1], i_user_03_09_lut_08[19])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x8_status_ltssm_state[2], i_user_03_09_lut_08[18])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x8_status_ltssm_state[3], i_user_03_09_lut_08[17])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x8_status_ltssm_state[4], i_user_03_09_lut_08[16])
`ACX_BIND_USER_DESIGN_PORT(pci_express_x8_status_ltssm_state[5], i_user_03_09_lut_08[15])
    // Ports for pll_1
`ifdef ACX_CLK_NE_FULL
`ACX_BIND_USER_DESIGN_PORT(i_clk, i_user_06_09_trunk_00[16])
`ACX_BIND_USER_DESIGN_PORT(pll_1_lock, i_user_12_08_lut_17[0])
`endif

//////////////////////////////////////
// End IO Ring User Design Port Binding Include File
//////////////////////////////////////
