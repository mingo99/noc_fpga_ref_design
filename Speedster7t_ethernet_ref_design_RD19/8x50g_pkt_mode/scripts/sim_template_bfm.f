##--------------------------------------
## Simulation filelist template
## Suitable for fullchip BFM structures
##--------------------------------------
## Note : Any line that starts with ## will
##        not be included in the final output

# Speed up simulations
+define+SIMSTEP_RTL

# Fullchip include directories
+incdir+$ACX_DEVICE_INSTALL_DIR/sim/tb/fullchip/util
+incdir+$ACX_DEVICE_INSTALL_DIR

# Configure verilog libraries to look for modules
# using their extension
+libext+.v
+libext+.sv

## Indicate where the filelist is to be inserted
# [insert filelist here]

## Post filelist content can be included here

