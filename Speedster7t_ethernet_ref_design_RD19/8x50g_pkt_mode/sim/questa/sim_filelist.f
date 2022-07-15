
# -----------------------------------------------
# Autogenerated simulation filelist
# Do not edit this file as it will be overwritten
# Generated by D:/questasim64_10.7c/win64/../tcl/vsim/vsim on 14:16:18 Tue 02 Nov 21
# -----------------------------------------------


# Speed up simulations
+define+SIMSTEP_RTL

# Fullchip include directories
+incdir+$ACX_DEVICE_INSTALL_DIR/sim/tb/fullchip/util
+incdir+$ACX_DEVICE_INSTALL_DIR

# Configure verilog libraries to look for modules
# using their extension
+libext+.v
+libext+.sv


# -------------------------------------
# Filelist added files from ../../src/filelist.tcl
# -------------------------------------

# Verilog design file include directory
+incdir+../../src/include
# Verilog testbench file include directory
+incdir+../../src/tb

# Verilog source files
../../src/rtl/default_nettype.v
-sv ../../src/rtl/nap_ethernet_wrapper.sv
-sv ../../src/rtl/random_seq_engine.sv
-sv ../../src/rtl/reset_processor.sv
-sv ../../src/rtl/eth_pkt_gen.sv
-sv ../../src/rtl/eth_pkt_chk.sv
-sv ../../src/rtl/eth_fifo_256x512k.sv
-sv ../../src/rtl/eth_rx_4way_switch.sv
-sv ../../src/rtl/tx_100g_rate_limit.sv
-sv ../../src/rtl/ethernet_8x50g_pkt_mode_top.sv

# Verilog testbench files
-sv ../../src/tb/tb_eth_monitor.sv
-sv ../../src/tb/tb_ethernet_ref_design.sv

# -------------------------------------
# End of user filelist ../../src/filelist.tcl
# -------------------------------------




