//////////////////////////////////////
// ACE GENERATED VERILOG INCLUDE FILE
// Generated on: 2022.01.04 at 10:47:50 PST
// By: ACE 8.6.1
// From project: noc_2d_ref_design_top
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
`ACX_DEVICE_NAME.clocks.global_clk_nw.set_global_clocks('{{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{3200},{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{3200}});
`endif

// Global clocks driven from NE corner
`ifndef ACX_CLK_NE_FULL
`ACX_DEVICE_NAME.clocks.global_clk_ne.set_global_clocks('{{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0}});
`endif

// Global clocks driven from SE corner
`ifndef ACX_CLK_SE_FULL
`ACX_DEVICE_NAME.clocks.global_clk_se.set_global_clocks('{{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{2004},{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{2004}});
`endif

// Global clocks driven from SW corner
`ifndef ACX_CLK_SW_FULL
`ACX_DEVICE_NAME.clocks.global_clk_sw.set_global_clocks('{{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{3200},{5000},{2000},{5000},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{0},{3200},{5000},{2000}});
`endif


//////////////////////////////////////
// Config file loading for Cycle Accurate sims
// This is only applicable when using the FCU BFM
//////////////////////////////////////
`ifndef ACX_FCU_FULL
  `ifdef ACX_CLK_NW_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_QCM_NW.txt"}, "full");
  `endif
  `ifdef ACX_CLK_NW_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_CLKIO_NW.txt"}, "full");
  `endif
  `ifdef ACX_CLK_NW_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_PLL_NW_2.txt"}, "full");
  `endif
  `ifdef ACX_CLK_NE_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_QCM_NE.txt"}, "full");
  `endif
  `ifdef ACX_CLK_NE_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_CLKIO_NE.txt"}, "full");
  `endif
  `ifdef ACX_CLK_SE_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_QCM_SE.txt"}, "full");
  `endif
  `ifdef ACX_CLK_SE_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_CLKIO_SE.txt"}, "full");
  `endif
  `ifdef ACX_CLK_SE_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_PLL_SE_0.txt"}, "full");
  `endif
  `ifdef ACX_CLK_SW_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_QCM_SW.txt"}, "full");
  `endif
  `ifdef ACX_CLK_SW_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_CLKIO_SW.txt"}, "full");
  `endif
  `ifdef ACX_CLK_SW_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_PLL_SW_0.txt"}, "full");
  `endif
  `ifdef ACX_CLK_SW_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_PLL_SW_2.txt"}, "full");
  `endif
  `ifdef ACX_ENOC_RTL_INCLUDE
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream0_NOC.txt"}, "full");
  `endif
  `ifdef ACX_GPIO_S_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream1_GPIO_S_B0.txt"}, "full");
  `endif
  `ifdef ACX_GPIO_S_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream1_GPIO_S_B1.txt"}, "full");
  `endif
  `ifdef ACX_GPIO_S_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream1_GPIO_S_B2.txt"}, "full");
  `endif
  `ifdef ACX_GPIO_N_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream1_GPIO_N_B0.txt"}, "full");
  `endif
  `ifdef ACX_GPIO_N_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream1_GPIO_N_B1.txt"}, "full");
  `endif
  `ifdef ACX_GPIO_N_FULL
    `ACX_DEVICE_NAME.fcu.configure( {`ACX_IORING_SIM_FILES_PATH, "noc_2d_ref_design_top_ioring_bitstream1_GPIO_N_B2.txt"}, "full");
  `endif
`endif

//////////////////////////////////////
// End IO Ring Simulation Configuration Include File
//////////////////////////////////////
