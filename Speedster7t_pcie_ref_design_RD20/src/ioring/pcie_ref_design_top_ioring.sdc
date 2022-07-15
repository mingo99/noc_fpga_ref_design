#######################################
# ACE GENERATED SDC FILE
# Generated on: 2021.05.04 at 06:44:45 PDT
# By: ACE 8.3.3
# From project: pcie_ref_design_top
#######################################
# IO Ring Boundary SDC File
#######################################

# Boundary clocks for clock_io_bank

# Boundary clocks for gpio_bank_north

# Boundary clocks for noc

# Boundary clocks for pci_express_x16

# Boundary clocks for pci_express_x8

# Boundary clocks for pll_1
create_clock -period 2.0 i_clk
# Frequency = 500.0 MHz
set_clock_uncertainty -setup 0.02 [get_clocks i_clk]


# Virtual clocks for IO Ring IPs
create_clock -name v_acx_sc_PCIEX16_AXI_MASTER_CLK -period 1.0
create_clock -name v_acx_sc_PCIEX16_AXI_SLAVE_CLK -period 1.0
create_clock -name v_acx_sc_PCIEX8_AXI_MASTER_CLK -period 1.0
create_clock -name v_acx_sc_PCIEX8_AXI_SLAVE_CLK -period 1.0

######################################
# End IO Ring Boundary SDC File
######################################
