//////////////////////////////////////
// ACE GENERATED VERILOG INCLUDE FILE
// Generated on: 2021.05.04 at 06:44:45 PDT
// By: ACE 8.3.3
// From project: pcie_ref_design_top
//////////////////////////////////////
// IO Ring Simulation Configuration Include File
// 
// This file must be included in your testbench
// after you instantiate the Device Simulation Model (DSM)
//////////////////////////////////////

//////////////////////////////////////
// Clocks
//////////////////////////////////////
// Global clocks driven from NW corner
`ifndef ACX_CLK_NW_FULL
ac7t1500.clocks.global_clk_nw.set_global_clocks('{{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0}});
`endif

// Global clocks driven from NE corner
`ifndef ACX_CLK_NE_FULL
ac7t1500.clocks.global_clk_ne.set_global_clocks('{{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{1000},{2000},{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{1000},{2000}});
`endif

// Global clocks driven from SE corner
`ifndef ACX_CLK_SE_FULL
ac7t1500.clocks.global_clk_se.set_global_clocks('{{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0}});
`endif

// Global clocks driven from SW corner
`ifndef ACX_CLK_SW_FULL
ac7t1500.clocks.global_clk_sw.set_global_clocks('{{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0}});
`endif


//////////////////////////////////////
// Config file loading for Cycle Accurate sims
// This is only applicable when using the FCU BFM
//////////////////////////////////////
`ifndef ACX_FCU_FULL
  `ifdef ACX_PCIE_0_FULL
    // Use locally generated configuration file.  Not this file
    // ac7t1500.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "pcie_ref_design_top_ioring_bitstream0_PCIE_0.txt"}, "full");
  `endif
  `ifdef ACX_PCIE_1_FULL
    // Use locally generated configuration file.  Not this file
    // ac7t1500.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "pcie_ref_design_top_ioring_bitstream0_PCIE_1.txt"}, "full");
  `endif
  `ifdef ACX_CLK_NW_FULL
    ac7t1500.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "pcie_ref_design_top_ioring_bitstream0_QCM_NW.txt"}, "full");
  `endif
  `ifdef ACX_CLK_NE_FULL
    ac7t1500.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "pcie_ref_design_top_ioring_bitstream0_QCM_NE.txt"}, "full");
  `endif
  `ifdef ACX_CLK_NE_FULL
    ac7t1500.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "pcie_ref_design_top_ioring_bitstream0_CLKIO_NE.txt"}, "full");
  `endif
  `ifdef ACX_CLK_NE_FULL
    ac7t1500.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "pcie_ref_design_top_ioring_bitstream0_PLL_NE_0.txt"}, "full");
  `endif
  `ifdef ACX_CLK_SE_FULL
    ac7t1500.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "pcie_ref_design_top_ioring_bitstream0_QCM_SE.txt"}, "full");
  `endif
  `ifdef ACX_CLK_SW_FULL
    ac7t1500.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "pcie_ref_design_top_ioring_bitstream0_QCM_SW.txt"}, "full");
  `endif
  `ifdef ACX_ENOC_RTL_INCLUDE
    ac7t1500.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "pcie_ref_design_top_ioring_bitstream0_NOC.txt"}, "full");
  `endif
  `ifdef ACX_GPIO_N_FULL
    ac7t1500.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "pcie_ref_design_top_ioring_bitstream1_GPIO_N_B0.txt"}, "full");
  `endif
`endif

//////////////////////////////////////
// End IO Ring Simulation Configuration Include File
//////////////////////////////////////
