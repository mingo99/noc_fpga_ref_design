#####################################
# Simulation filelist template
#####################################

## Note : Any line that starts with ## will
##        not be included in the final output

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

## Indicate where the filelist is to be inserted
# [insert filelist here]

## Post filelist content can be included here


