//////////////////////////////////////
// ACE GENERATED VERILOG INCLUDE FILE
// Generated on: 2021.05.04 at 06:44:45 PDT
// By: ACE 8.3.3
// From project: pcie_ref_design_top
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
// PCIE_0:
  // AUX clock
  `define ACX_PCIE_0_AUX_CLK_SEL = 4;
  // Master clock
  `define ACX_PCIE_0_MASTER_CLK_SEL = 4;
  // Slave clock
  `define ACX_PCIE_0_SLAVE_CLK_SEL = 4;

//////////////////////////////////////
// PCIE_1:
  // AUX clock
  `define ACX_PCIE_1_AUX_CLK_SEL = 4;
  // Master clock
  `define ACX_PCIE_1_MASTER_CLK_SEL = 4;
  // Slave clock
  `define ACX_PCIE_1_SLAVE_CLK_SEL = 4;

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
// GPIO_N_B0:
  `define ACX_GPIO_N_B0_RST_SEL = 27;

//////////////////////////////////////
// PCIE_1:
  `define ACX_PCIE_1_RST_SEL = 15;

//////////////////////////////////////
// PCIE_0:
  `define ACX_PCIE_0_RST_SEL = 14;

//////////////////////////////////////
// End IO Ring Simulation Defines Include File
//////////////////////////////////////
