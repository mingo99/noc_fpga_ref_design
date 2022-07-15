//////////////////////////////////////
// ACE GENERATED VERILOG INCLUDE FILE
// Generated on: 2021.05.04 at 06:44:45 PDT
// By: ACE 8.3.3
// From project: pcie_ref_design_top
//////////////////////////////////////
// User Design Port List Include File
//////////////////////////////////////

    // Ports for clock_io_bank
    // Ports for gpio_bank_north
    input        i_reset_n,
    input        i_start,
    output       o_fail,
    output       o_fail_oe,
    output       o_mstr_test_complete,
    output       o_mstr_test_complete_oe,
    // Ports for noc
    // Ports for pci_express_x16
    // Status
    input  [3:0] pci_express_x16_status_flr_pf_active,
    input        pci_express_x16_status_flr_vf_active,
    input  [5:0] pci_express_x16_status_ltssm_state,
    // Ports for pci_express_x8
    // Status
    input  [5:0] pci_express_x8_status_ltssm_state,
    // Ports for pll_1
    input        i_clk,
    input        pll_1_lock 

//////////////////////////////////////
// End User Design Port List Include File
//////////////////////////////////////
