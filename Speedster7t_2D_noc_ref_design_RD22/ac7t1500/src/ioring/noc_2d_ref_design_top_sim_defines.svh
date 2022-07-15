//////////////////////////////////////
// ACE GENERATED VERILOG INCLUDE FILE
// Generated on: 2022.01.04 at 10:47:50 PST
// By: ACE 8.6.1
// From project: noc_2d_ref_design_top
//////////////////////////////////////
// IO Ring Simulation Defines Include File
// 
// This file must be included in your compilation
// prior to the Device Simulation Model (DSM) being compiled
//////////////////////////////////////


//////////////////////////////////////
// Switch to set SystemVerilog Direct Connect
// Interfaces in DSM to Monitor-Only Mode.
// This is required when using the IO Designer
// generated user design port bindings file.
//////////////////////////////////////
  `define ACX_ENABLE_DCI_MONITOR_MODE = 1;

//////////////////////////////////////
// Clock Selects in each IP
//////////////////////////////////////

//////////////////////////////////////
// GPIO_S_B1:
  // Bank clock
  `define ACX_GPIO_S_B1_CLK_SEL = 32;

//////////////////////////////////////
// NoC:
  // NoC Ref clock
  `define ENOC_CLK_SEL = 15;

//////////////////////////////////////
// Reset Selects in each IP
//////////////////////////////////////

//////////////////////////////////////
// CLKIO_NE:
  `define ACX_CLKIO_NE_RST_SEL = 3;

//////////////////////////////////////
// CLKIO_NW:
  `define ACX_CLKIO_NW_RST_SEL = 2;

//////////////////////////////////////
// CLKIO_SE:
  `define ACX_CLKIO_SE_RST_SEL = 1;

//////////////////////////////////////
// CLKIO_SW:
  `define ACX_CLKIO_SW_RST_SEL = 0;

//////////////////////////////////////
// GPIO_N_B0:
  `define ACX_GPIO_N_B0_RST_SEL = 27;

//////////////////////////////////////
// GPIO_N_B1:
  `define ACX_GPIO_N_B1_RST_SEL = 27;

//////////////////////////////////////
// GPIO_N_B2:
  `define ACX_GPIO_N_B2_RST_SEL = 27;

//////////////////////////////////////
// GPIO_S_B0:
  `define ACX_GPIO_S_B0_RST_SEL = 27;

//////////////////////////////////////
// GPIO_S_B1:
  `define ACX_GPIO_S_B1_RST_SEL = 27;

//////////////////////////////////////
// GPIO_S_B2:
  `define ACX_GPIO_S_B2_RST_SEL = 27;

//////////////////////////////////////
// End IO Ring Simulation Defines Include File
//////////////////////////////////////
