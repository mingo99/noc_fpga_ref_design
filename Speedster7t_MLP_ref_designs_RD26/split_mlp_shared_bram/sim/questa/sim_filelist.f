
# -----------------------------------------------
# Autogenerated simulation filelist
# Do not edit this file as it will be overwritten
# Generated by D:/questasim64_10.7c/win64/../tcl/vsim/vsim on 14:44:38 Tue 02 Nov 21
# -----------------------------------------------

# Simulation filelist template


# Speed up simulations
+define+SIMSTEP_RTL

# Library paths
+incdir+$ACE_INSTALL_DIR/libraries

# Configure verilog libraries to look for modules
# using their extension
+libext+.v
+libext+.sv

# Include IP models
# $ACE_INSTALL_DIR/libraries/device_models/7t_simmodels.v
$ACE_INSTALL_DIR/libraries/device_models/AC7t1500ES0_simmodels.sv 


# -------------------------------------
# Filelist added files from ../../src/filelist.tcl
# -------------------------------------

# Verilog design file include directory
+incdir+../../src/include
# Verilog testbench file include directory
+incdir+../../src/tb

# Verilog source files
-sv ../../src/rtl/default_nettype.sv
-sv ../../src/rtl/pipeline.sv
-sv ../../src/rtl/group_2_mlp_1_bram.sv
-sv ../../src/rtl/split_mlp_shared_bram_stack.sv
-sv ../../src/rtl/split_mlp_shared_bram.sv

# Verilog testbench files
-sv ../../src/tb/tb_split_mlp_shared_bram.sv

# -------------------------------------
# End of user filelist ../../src/filelist.tcl
# -------------------------------------





